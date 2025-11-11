<?php

namespace App\Http\Controllers;

use App\Services\MpesaService;
use App\Services\PaymentSmsService;
use Illuminate\Http\Request;
use App\Models\Payment;
use App\Models\Contribution;
use App\Models\Pledge;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class MpesaController extends Controller
{
    protected $mpesa;
    protected $paymentSmsService;

    public function __construct(MpesaService $mpesa, PaymentSmsService $paymentSmsService)
    {
        $this->mpesa = $mpesa;
        $this->paymentSmsService = $paymentSmsService;
    }

    public function stkPush(Request $request)
    {
        $request->validate([
            'phone' => 'required|string',
            'amount' => 'required|numeric|min:1',
            'reference' => 'nullable|string|max:50',
            'breakdown' => 'nullable|array',
            'breakdown.*' => 'numeric|min:0',
        ]);

        $reference = $request->input('reference', 'Wallet');
        $breakdown = $request->input('breakdown', []);
        
        // Log the STK push request for debugging
        Log::info('M-Pesa STK Push initiated', [
            'phone' => $request->phone,
            'amount' => $request->amount,
            'reference' => $reference,
            'breakdown' => $breakdown
        ]);
        
        $response = $this->mpesa->stkPush($request->phone, $request->amount, $reference);

        // Store the account reference and breakdown temporarily for callback retrieval
        if (isset($response['CheckoutRequestID'])) {
            $this->storeAccountReference($response['CheckoutRequestID'], $reference);
            if (!empty($breakdown)) {
                $this->storeBreakdown($response['CheckoutRequestID'], $breakdown);
            }
        }

        return response()->json($response);
    }

    public function callback(Request $request)
    {
        // M-Pesa will post transaction details here
        $data = $request->all();

        // Parse callback and persist ONLY on success
        $body = $data['Body']['stkCallback'] ?? [];
        $checkoutRequestId = $body['CheckoutRequestID'] ?? null;
        $merchantRequestId = $body['MerchantRequestID'] ?? null;
        $resultCode = (int)($body['ResultCode'] ?? -1);
        $resultDesc = $body['ResultDesc'] ?? null;
        $phone = null;
        $amount = null;

        // Log all callbacks for debugging
        Log::info('M-Pesa Callback received', [
            'checkout_request_id' => $checkoutRequestId,
            'result_code' => $resultCode,
            'result_desc' => $resultDesc,
            'body' => $body
        ]);

        // Only process successful transactions (result_code = 0)
        // Other codes: 1 = cancelled, 1032 = cancelled by user, etc.
        if ($resultCode === 0) {
            $items = $body['CallbackMetadata']['Item'] ?? [];
            $amount = 0.0;
            $phone = '';
            $mpesaReceipt = null;
            $accountReference = null;
            foreach ($items as $item) {
                switch ($item['Name'] ?? '') {
                    case 'Amount':
                        $amount = (float)($item['Value'] ?? 0);
                        break;
                    case 'MpesaReceiptNumber':
                        $mpesaReceipt = $item['Value'] ?? null;
                        break;
                    case 'PhoneNumber':
                        $phone = (string)($item['Value'] ?? '');
                        break;
                    case 'AccountReference':
                        $accountReference = (string)($item['Value'] ?? '');
                        break;
                }
            }

            // Only save if we have a valid M-Pesa receipt number
            if (!empty($mpesaReceipt) && $amount > 0) {
                try {
                    // Check for duplicate transactions
                    $existingPayment = Payment::where('checkout_request_id', $checkoutRequestId)
                        ->orWhere('mpesa_receipt_number', $mpesaReceipt)
                        ->first();
                    
                    if ($existingPayment) {
                        Log::warning('Duplicate M-Pesa transaction detected', [
                            'checkout_request_id' => $checkoutRequestId,
                            'mpesa_receipt' => $mpesaReceipt,
                            'existing_payment_id' => $existingPayment->id
                        ]);
                        return response()->json(['status' => 'duplicate_ignored']);
                    }
                    
                    // If account reference is not provided by M-Pesa, retrieve from cache
                    if (empty($accountReference)) {
                        $accountReference = $this->getAccountReference($checkoutRequestId);
                        Log::info('Retrieved account reference from cache', [
                            'checkout_request_id' => $checkoutRequestId,
                            'account_reference' => $accountReference
                        ]);
                    }
                    
                    // Extract member ID from account reference
                    $memberId = $this->extractMemberIdFromReference($accountReference);
                    
                    try {
                        DB::beginTransaction();
                        
                        $payment = Payment::create([
                            'merchant_request_id' => $merchantRequestId,
                            'checkout_request_id' => $checkoutRequestId,
                            'account_reference' => $accountReference,
                            'phone' => $phone,
                            'amount' => $amount,
                            'mpesa_receipt_number' => $mpesaReceipt,
                            'result_code' => (string)$resultCode,
                            'result_desc' => $resultDesc,
                            'status' => 'confirmed',
                            'member_id' => $memberId,
                        ]);

                        // Create contributions from breakdown if available
                        $breakdown = $this->getBreakdown($checkoutRequestId);
                        
                        Log::info('Processing contributions', [
                            'payment_id' => $payment->id,
                            'checkout_request_id' => $checkoutRequestId,
                            'member_id' => $memberId,
                            'breakdown' => $breakdown,
                            'breakdown_empty' => empty($breakdown),
                            'has_member_id' => !empty($memberId),
                            'breakdown_count' => is_array($breakdown) ? count($breakdown) : 0
                        ]);
                        
                        if (!empty($breakdown) && $memberId) {
                            // Ensure breakdown is an array
                            if (!is_array($breakdown)) {
                                Log::error('Breakdown is not an array', [
                                    'breakdown_type' => gettype($breakdown),
                                    'breakdown_value' => $breakdown
                                ]);
                            } else {
                                $contributionsCreated = 0;
                                $contributionsFailed = 0;
                                
                                foreach ($breakdown as $accountType => $contributionAmountValue) {
                                    // Convert to float if needed
                                    $contributionAmount = (float)$contributionAmountValue;
                                    
                                    if ($contributionAmount > 0) {
                                        try {
                                            Log::info('Creating contribution', [
                                                'member_id' => $memberId,
                                                'payment_id' => $payment->id,
                                                'account_type' => $accountType,
                                                'amount' => $contributionAmount
                                            ]);
                                            
                                            $contribution = Contribution::create([
                                                'member_id' => $memberId,
                                                'payment_id' => $payment->id,
                                                'contribution_type' => $accountType,
                                                'amount' => $contributionAmount,
                                                'reference_number' => $mpesaReceipt,
                                                'payment_method' => 'mpesa',
                                                'contribution_date' => now(),
                                                'status' => 'completed',
                                            ]);
                                            
                                            $contributionsCreated++;
                                            
                                            Log::info('Contribution created successfully', [
                                                'contribution_id' => $contribution->id,
                                                'account_type' => $accountType,
                                                'amount' => $contributionAmount
                                            ]);

                                            // Decrement pledges for this account type (if pledges exist)
                                            // This happens within the transaction, so pledges are updated atomically
                                            try {
                                                $this->decrementPledges($memberId, $accountType, $contributionAmount);
                                            } catch (\Exception $pledgeError) {
                                                // Log but don't fail the transaction if pledge decrement fails
                                                Log::warning('Failed to decrement pledges, but contribution was saved', [
                                                    'member_id' => $memberId,
                                                    'account_type' => $accountType,
                                                    'error' => $pledgeError->getMessage()
                                                ]);
                                            }
                                        } catch (\Exception $contributionError) {
                                            $contributionsFailed++;
                                            // Log contribution creation errors but continue with other contributions
                                            Log::error('Failed to create contribution', [
                                                'member_id' => $memberId,
                                                'account_type' => $accountType,
                                                'amount' => $contributionAmount,
                                                'payment_id' => $payment->id,
                                                'error' => $contributionError->getMessage(),
                                                'trace' => $contributionError->getTraceAsString()
                                            ]);
                                        }
                                    }
                                }
                                
                                Log::info('Contributions processing completed', [
                                    'payment_id' => $payment->id,
                                    'member_id' => $memberId,
                                    'breakdown' => $breakdown,
                                    'contributions_created' => $contributionsCreated,
                                    'contributions_failed' => $contributionsFailed
                                ]);
                            }
                        } else {
                            // Fallback: Create contribution from account reference if breakdown is missing
                            if (empty($breakdown) && $memberId && !empty($accountReference)) {
                                Log::warning('Breakdown missing, attempting to create contribution from account reference', [
                                    'payment_id' => $payment->id,
                                    'checkout_request_id' => $checkoutRequestId,
                                    'member_id' => $memberId,
                                    'account_reference' => $accountReference,
                                    'amount' => $amount
                                ]);
                                
                                try {
                                    $accountType = $this->parseAccountTypeFromReference($accountReference);
                                    if ($accountType && $accountType !== 'MULTI') {
                                        $contribution = Contribution::create([
                                            'member_id' => $memberId,
                                            'payment_id' => $payment->id,
                                            'contribution_type' => $accountType,
                                            'amount' => $amount,
                                            'reference_number' => $mpesaReceipt,
                                            'payment_method' => 'mpesa',
                                            'contribution_date' => now(),
                                            'status' => 'completed',
                                        ]);
                                        
                                        Log::info('Fallback contribution created from account reference', [
                                            'contribution_id' => $contribution->id,
                                            'account_type' => $accountType,
                                            'amount' => $amount
                                        ]);
                                    } else {
                                        // If MULTI or unknown, create as "Others"
                                        $contribution = Contribution::create([
                                            'member_id' => $memberId,
                                            'payment_id' => $payment->id,
                                            'contribution_type' => 'Others',
                                            'amount' => $amount,
                                            'reference_number' => $mpesaReceipt,
                                            'payment_method' => 'mpesa',
                                            'contribution_date' => now(),
                                            'status' => 'completed',
                                        ]);
                                        
                                        Log::info('Fallback contribution created as "Others"', [
                                            'contribution_id' => $contribution->id,
                                            'amount' => $amount
                                        ]);
                                    }
                                } catch (\Exception $fallbackError) {
                                    Log::error('Failed to create fallback contribution', [
                                        'payment_id' => $payment->id,
                                        'member_id' => $memberId,
                                        'error' => $fallbackError->getMessage(),
                                        'trace' => $fallbackError->getTraceAsString()
                                    ]);
                                }
                            } else {
                                Log::warning('No breakdown or member ID available for contribution creation', [
                                    'payment_id' => $payment->id,
                                    'checkout_request_id' => $checkoutRequestId,
                                    'member_id' => $memberId,
                                    'breakdown' => $breakdown,
                                    'breakdown_empty' => empty($breakdown),
                                    'member_id_empty' => empty($memberId),
                                    'account_reference' => $accountReference ?? null
                                ]);
                            }
                        }

                        DB::commit();
                        
                        Log::info('Payment and contributions saved successfully', [
                            'payment_id' => $payment->id,
                            'checkout_request_id' => $checkoutRequestId,
                            'mpesa_receipt' => $mpesaReceipt,
                            'amount' => $amount,
                            'account_reference' => $accountReference,
                            'member_id' => $memberId,
                            'breakdown' => $breakdown ?? null
                        ]);
                    } catch (\Illuminate\Database\QueryException $e) {
                        DB::rollBack();
                        // Handle unique constraint violations
                        if ($e->getCode() == 23000) { // Integrity constraint violation
                            Log::warning('Duplicate transaction prevented by database constraint', [
                                'checkout_request_id' => $checkoutRequestId,
                                'mpesa_receipt' => $mpesaReceipt,
                                'error' => $e->getMessage()
                            ]);
                            return response()->json(['status' => 'duplicate_prevented']);
                        }
                        // Re-throw to be caught by outer catch block
                        throw $e;
                    } catch (\Exception $e) {
                        DB::rollBack();
                        Log::error('Transaction failed during payment processing', [
                            'checkout_request_id' => $checkoutRequestId,
                            'mpesa_receipt' => $mpesaReceipt,
                            'error' => $e->getMessage(),
                            'trace' => $e->getTraceAsString()
                        ]);
                        throw $e;
                    }

                    // Send payment confirmation SMS after contributions are created
                    // Refresh payment to ensure contributions relationship is loaded
                    try {
                        $payment->refresh();
                        $payment->load('contributions');
                        
                        Log::info('Sending payment confirmation SMS', [
                            'payment_id' => $payment->id,
                            'member_id' => $memberId,
                            'contributions_count' => $payment->contributions->count()
                        ]);
                        
                        $smsSent = $this->paymentSmsService->sendPaymentConfirmation($payment);
                        
                        if ($smsSent) {
                            Log::info('Thank you SMS sent successfully after contribution creation', [
                                'payment_id' => $payment->id,
                                'member_id' => $memberId
                            ]);
                        } else {
                            Log::warning('Failed to send thank you SMS', [
                                'payment_id' => $payment->id,
                                'member_id' => $memberId
                            ]);
                        }
                    } catch (\Exception $e) {
                        Log::error('Failed to send payment confirmation SMS: ' . $e->getMessage(), [
                            'payment_id' => $payment->id,
                            'member_id' => $memberId,
                            'trace' => $e->getTraceAsString()
                        ]);
                    }
                } catch (\Throwable $e) {
                    Log::error('Failed to persist successful STK callback: '.$e->getMessage(), ['checkout' => $checkoutRequestId]);
                }
            } else {
                Log::warning('M-Pesa callback successful but missing receipt or amount', [
                    'checkout_request_id' => $checkoutRequestId,
                    'mpesa_receipt' => $mpesaReceipt,
                    'amount' => $amount
                ]);
            }
        } else {
            // Handle different failure scenarios
            $failureReason = match($resultCode) {
                1 => 'User cancelled the transaction',
                1032 => 'User cancelled the transaction',
                2001 => 'Wrong PIN entered',
                2002 => 'Insufficient funds',
                2003 => 'Transaction failed',
                default => 'Transaction failed with code: ' . $resultCode
            };
            
            Log::info('M-Pesa transaction failed', [
                'checkout_request_id' => $checkoutRequestId,
                'result_code' => $resultCode,
                'result_desc' => $resultDesc,
                'failure_reason' => $failureReason
            ]);

            // Persist a failed payment record so clients can surface the message
            try {
                // Try get account reference from cache (it may not be in failure callback body)
                $accountReference = $this->getAccountReference($checkoutRequestId);

                // Upsert by checkout_request_id
                $payment = Payment::updateOrCreate(
                    ['checkout_request_id' => $checkoutRequestId],
                    [
                        'merchant_request_id' => $merchantRequestId,
                        'account_reference' => $accountReference,
                        'phone' => $phone ?: '0000000000', // Use phone from callback or default
                        'amount' => $amount ?: 0, // Use amount from callback or default
                        'result_code' => (string)$resultCode,
                        'result_desc' => $resultDesc ?: $failureReason,
                        'status' => 'failed',
                    ]
                );
            } catch (\Throwable $e) {
                Log::error('Failed to persist failed STK callback: ' . $e->getMessage(), [
                    'checkout_request_id' => $checkoutRequestId,
                ]);
            }
        }

        return response()->json([
            'ResultCode' => 0,
            'ResultDesc' => 'Success',
        ]);
    }

    /**
     * Parse account type from account reference
     * Account reference format: {e_kanisa_number}{account_type_code}
     * Codes: T=Tithe, O=Offering, D=Development, TG=Thanksgiving, FF=FirstFruit, OT=Others, MULTI=Multiple
     */
    private function parseAccountTypeFromReference($accountReference)
    {
        if (empty($accountReference)) {
            return null;
        }

        // Check if it ends with MULTI
        if (str_ends_with($accountReference, 'MULTI')) {
            return 'MULTI';
        }

        // Extract the suffix (last 1-2 characters)
        $suffix = substr($accountReference, -2);
        
        // Map codes to account types
        $codeMap = [
            'T' => 'Tithe',
            'O' => 'Offering',
            'D' => 'Development',
            'TG' => 'Thanksgiving',
            'FF' => 'FirstFruit',
            'OT' => 'Others',
        ];

        // Check 2-character codes first (TG, FF, OT)
        if (isset($codeMap[$suffix])) {
            return $codeMap[$suffix];
        }

        // Check 1-character codes
        $singleChar = substr($accountReference, -1);
        if (isset($codeMap[$singleChar])) {
            return $codeMap[$singleChar];
        }

        // Default to Others if unknown
        return 'Others';
    }

    /**
     * Extract member ID from account reference
     * Account reference format: {e_kanisa_number}{account_type_code}
     * e.g., "12345T" where 12345 is e_kanisa_number and T is account type
     */
    private function extractMemberIdFromReference($accountReference)
    {
        if (empty($accountReference)) {
            return null;
        }

        try {
            // Handle different account reference formats
            $eKanisaNumber = null;
            
            // Check if it's a MULTI reference (contains MULTI at the end)
            if (str_ends_with($accountReference, 'MULTI')) {
                $eKanisaNumber = str_replace('MULTI', '', $accountReference);
            } else {
                // Remove single character account type suffixes (T, O, D, TG, FF, OT)
                $eKanisaNumber = preg_replace('/[TODGFF]+$/', '', $accountReference);
            }
            
            if (empty($eKanisaNumber)) {
                Log::warning('Could not extract e_kanisa_number from account reference', [
                    'account_reference' => $accountReference
                ]);
                return null;
            }

            // Find member by e_kanisa_number
            $member = \App\Models\Member::where('e_kanisa_number', $eKanisaNumber)->first();
            
            if ($member) {
                Log::info('Member found for account reference', [
                    'account_reference' => $accountReference,
                    'e_kanisa_number' => $eKanisaNumber,
                    'member_id' => $member->id
                ]);
                return $member->id;
            } else {
                Log::warning('Member not found for account reference', [
                    'account_reference' => $accountReference,
                    'e_kanisa_number' => $eKanisaNumber
                ]);
                return null;
            }
        } catch (\Exception $e) {
            Log::error('Error extracting member ID from reference: ' . $e->getMessage(), [
                'account_reference' => $accountReference
            ]);
            return null;
        }
    }

    /**
     * Store account reference temporarily for callback retrieval
     */
    private function storeAccountReference($checkoutRequestId, $accountReference)
    {
        try {
            // Store in cache for 24 hours
            \Illuminate\Support\Facades\Cache::put(
                "mpesa_account_ref_{$checkoutRequestId}",
                $accountReference,
                now()->addHours(24)
            );
            
            Log::info('Account reference stored', [
                'checkout_request_id' => $checkoutRequestId,
                'account_reference' => $accountReference
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to store account reference: ' . $e->getMessage());
        }
    }

    /**
     * Retrieve account reference from temporary storage
     */
    private function getAccountReference($checkoutRequestId)
    {
        try {
            return \Illuminate\Support\Facades\Cache::get("mpesa_account_ref_{$checkoutRequestId}");
        } catch (\Exception $e) {
            Log::error('Failed to retrieve account reference: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Store breakdown data temporarily for callback retrieval
     */
    private function storeBreakdown($checkoutRequestId, $breakdown)
    {
        try {
            // Ensure breakdown is an array
            if (!is_array($breakdown)) {
                Log::warning('Breakdown is not an array when storing', [
                    'breakdown_type' => gettype($breakdown),
                    'breakdown_value' => $breakdown
                ]);
                $breakdown = (array)$breakdown;
            }
            
            // Store in cache for 24 hours
            \Illuminate\Support\Facades\Cache::put(
                "mpesa_breakdown_{$checkoutRequestId}",
                $breakdown,
                now()->addHours(24)
            );
            
            // Verify it was stored
            $stored = \Illuminate\Support\Facades\Cache::get("mpesa_breakdown_{$checkoutRequestId}");
            
            Log::info('Breakdown stored', [
                'checkout_request_id' => $checkoutRequestId,
                'breakdown' => $breakdown,
                'breakdown_count' => count($breakdown),
                'stored_verified' => !is_null($stored),
                'cache_driver' => config('cache.default')
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to store breakdown: ' . $e->getMessage(), [
                'checkout_request_id' => $checkoutRequestId,
                'breakdown' => $breakdown,
                'trace' => $e->getTraceAsString()
            ]);
        }
    }

    /**
     * Retrieve breakdown data from temporary storage
     */
    private function getBreakdown($checkoutRequestId)
    {
        try {
            $breakdown = \Illuminate\Support\Facades\Cache::get("mpesa_breakdown_{$checkoutRequestId}");
            
            Log::info('Breakdown retrieval attempt', [
                'checkout_request_id' => $checkoutRequestId,
                'breakdown_found' => !is_null($breakdown),
                'breakdown' => $breakdown,
                'breakdown_type' => gettype($breakdown),
                'is_array' => is_array($breakdown)
            ]);
            
            return $breakdown;
        } catch (\Exception $e) {
            Log::error('Failed to retrieve breakdown: ' . $e->getMessage(), [
                'checkout_request_id' => $checkoutRequestId,
                'trace' => $e->getTraceAsString()
            ]);
            return null;
        }
    }

    /**
     * Decrement pledges when a contribution is made
     */
    private function decrementPledges($memberId, $accountType, $contributionAmount)
    {
        try {
            // Get active pledges for this member and account type
            $pledges = Pledge::where('member_id', $memberId)
                ->where('account_type', $accountType)
                ->where('status', 'active')
                ->where('remaining_amount', '>', 0)
                ->orderBy('pledge_date', 'asc') // Fulfill oldest pledges first
                ->get();

            $remainingToDecrement = $contributionAmount;

            foreach ($pledges as $pledge) {
                if ($remainingToDecrement <= 0) {
                    break;
                }

                $amountToDecrement = min($remainingToDecrement, $pledge->remaining_amount);
                $pledge->decrementRemaining($amountToDecrement);
                $remainingToDecrement -= $amountToDecrement;

                Log::info('Pledge decremented', [
                    'pledge_id' => $pledge->id,
                    'member_id' => $memberId,
                    'account_type' => $accountType,
                    'amount_decremented' => $amountToDecrement,
                    'remaining_pledge' => $pledge->remaining_amount
                ]);
            }
        } catch (\Exception $e) {
            Log::error('Error decrementing pledges', [
                'member_id' => $memberId,
                'account_type' => $accountType,
                'contribution_amount' => $contributionAmount,
                'error' => $e->getMessage()
            ]);
        }
    }
}
