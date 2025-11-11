<?php

namespace App\Services;

use App\Models\Member;
use App\Models\Payment;
use Illuminate\Support\Facades\Log;

class PaymentSmsService
{
    protected SmsService $smsService;

    public function __construct(SmsService $smsService)
    {
        $this->smsService = $smsService;
    }

    /**
     * Send payment confirmation SMS to member
     */
    public function sendPaymentConfirmation(Payment $payment): bool
    {
        try {
            // Get member details
            $member = $payment->member;
            if (!$member) {
                Log::warning('Cannot send payment SMS: Member not found', [
                    'payment_id' => $payment->id,
                    'member_id' => $payment->member_id
                ]);
                return false;
            }

            // Format phone number
            $phoneNumber = $this->normalizePhoneNumber($payment->phone);
            if (!$phoneNumber) {
                Log::warning('Cannot send payment SMS: Invalid phone number', [
                    'payment_id' => $payment->id,
                    'phone' => $payment->phone
                ]);
                return false;
            }

            // Generate SMS message
            $message = $this->generatePaymentMessage($member, $payment);

            // Send SMS
            $success = $this->smsService->sendSms($phoneNumber, $message);

            if ($success) {
                Log::info('Payment confirmation SMS sent successfully', [
                    'payment_id' => $payment->id,
                    'member_id' => $member->id,
                    'phone' => $phoneNumber,
                    'amount' => $payment->amount
                ]);

                // Send additional congratulatory message for special cases
                $this->sendSpecialCongratulatoryMessage($member, $payment);
            } else {
                Log::error('Failed to send payment confirmation SMS', [
                    'payment_id' => $payment->id,
                    'member_id' => $member->id,
                    'phone' => $phoneNumber
                ]);
            }

            return $success;

        } catch (\Exception $e) {
            Log::error('Payment SMS service error: ' . $e->getMessage(), [
                'payment_id' => $payment->id,
                'member_id' => $payment->member_id
            ]);
            return false;
        }
    }

    /**
     * Generate payment confirmation message
     */
    protected function generatePaymentMessage(Member $member, Payment $payment): string
    {
        // Refresh to ensure contributions are loaded
        $payment->refresh();
        $payment->load('contributions');
        
        $amount = number_format($payment->amount, 2);
        $receiptNumber = $payment->mpesa_receipt_number;
        $date = $payment->created_at->format('d/m/Y H:i');

        // Get contribution breakdown
        $contributions = $payment->contributions()->where('status', 'completed')->get();
        
        // Check if payment contributed to any pledges
        // Get account types from contributions
        $contributionAccountTypes = $contributions->pluck('contribution_type')->unique()->toArray();
        
        // Check for active pledges that match these account types
        $activePledges = \App\Models\Pledge::where('member_id', $member->id)
            ->whereIn('account_type', $contributionAccountTypes)
            ->where('status', 'active')
            ->get();
        
        // Also check recently fulfilled pledges (updated in last 10 minutes)
        $recentlyFulfilledPledges = \App\Models\Pledge::where('member_id', $member->id)
            ->whereIn('account_type', $contributionAccountTypes)
            ->where('status', 'fulfilled')
            ->where('updated_at', '>=', now()->subMinutes(10))
            ->get();
        
        $hasPledgeFulfillment = $activePledges->count() > 0 || $recentlyFulfilledPledges->count() > 0;
        $pledgesToMention = $recentlyFulfilledPledges->count() > 0 
            ? $recentlyFulfilledPledges 
            : $activePledges->take(3); // Show up to 3 pledges
        
        $message = "THANK YOU FOR YOUR GENEROUS CONTRIBUTION!\n\n";
        $message .= "Dear {$member->full_name},\n\n";
        
        if ($hasPledgeFulfillment) {
            $message .= "We are deeply grateful for your contribution! Your payment has helped fulfill your pledges to PCEA Church.\n\n";
        } else {
            $message .= "We are deeply grateful for your faithful giving to PCEA Church. Your contribution makes a significant difference in our ministry.\n\n";
        }
        
        if ($contributions->count() > 0) {
            $message .= "CONTRIBUTION BREAKDOWN:\n";
            foreach ($contributions as $contribution) {
                $contributionAmount = number_format($contribution->amount, 2);
                $message .= "- {$contribution->contribution_type}: KES {$contributionAmount}\n";
            }
            $message .= "\n";
        }
        
        if ($hasPledgeFulfillment && $pledgesToMention->count() > 0) {
            $message .= "PLEDGE UPDATE:\n";
            foreach ($pledgesToMention as $pledge) {
                if ($pledge->status === 'fulfilled') {
                    $message .= "✓ {$pledge->account_type} pledge fulfilled!\n";
                } else {
                    $percentage = $pledge->getFulfillmentPercentage();
                    $message .= "→ {$pledge->account_type}: {$percentage}% complete\n";
                }
            }
            $message .= "\n";
        }
        
        $message .= "TOTAL: KES {$amount}\n";
        $message .= "RECEIPT: {$receiptNumber}\n";
        $message .= "DATE: {$date}\n\n";
        
        $message .= "Your generosity blesses our church and enables us to support our ministries, serve our community, and spread the Gospel.\n\n";
        $message .= "May God bless you abundantly for your faithfulness!\n\n";
        $message .= "With gratitude,\n";
        $message .= "PCEA Church";

        return $message;
    }

    /**
     * Get account type from account reference
     */
    protected function getAccountTypeFromReference(?string $accountReference): string
    {
        if (empty($accountReference)) {
            return 'General Contribution';
        }

        // Extract account type from reference - look for specific suffixes at the end
        if (preg_match('/([TODGFF]+)$/', $accountReference, $matches)) {
            $suffix = $matches[1];
            
            return match($suffix) {
                'T' => 'Tithe',
                'O' => 'Offering',
                'D' => 'Development',
                'TG' => 'Thanksgiving',
                'FF' => 'First Fruit',
                'OT' => 'Others',
                default => 'General Contribution'
            };
        }
        
        return 'General Contribution';
    }

    /**
     * Normalize phone number for SMS
     */
    protected function normalizePhoneNumber(string $phoneNumber): ?string
    {
        $digits = preg_replace('/[^0-9]/', '', $phoneNumber);

        if (str_starts_with($digits, '0')) {
            return '254' . substr($digits, 1);
        }

        if (str_starts_with($digits, '254')) {
            return $digits;
        }

        if (str_starts_with($digits, '7') && strlen($digits) === 9) {
            return '254' . $digits;
        }

        return null;
    }

    /**
     * Send special congratulatory message for milestones or first-time contributors
     */
    protected function sendSpecialCongratulatoryMessage(Member $member, Payment $payment): void
    {
        try {
            $phoneNumber = $this->normalizePhoneNumber($payment->phone);
            if (!$phoneNumber) return;

            $totalContributions = $member->contributions()->where('status', 'completed')->sum('amount');
            $contributionCount = $member->contributions()->where('status', 'completed')->count();
            
            $specialMessage = null;

            // First-time contributor
            if ($contributionCount === 1) {
                $specialMessage = "WELCOME TO OUR GIVING FAMILY!\n\n";
                $specialMessage .= "Dear {$member->full_name},\n\n";
                $specialMessage .= "This is your first contribution to PCEA Church! We're thrilled to have you join our community of faithful givers.\n\n";
                $specialMessage .= "Your generosity makes a real difference in our church's mission. Thank you for taking this important step!\n\n";
                $specialMessage .= "May God bless you abundantly!\n\n";
                $specialMessage .= "PCEA Church APP";
            }
            // Milestone contributions
            elseif ($totalContributions >= 10000 && $totalContributions < 20000) {
                $specialMessage = "MILESTONE ACHIEVEMENT!\n\n";
                $specialMessage .= "Dear {$member->full_name},\n\n";
                $specialMessage .= "Congratulations! You've reached KES 10,000 in total contributions!\n\n";
                $specialMessage .= "Your consistent giving is truly inspiring and helps our church community thrive.\n\n";
                $specialMessage .= "Thank you for your faithfulness! God bless you!\n\n";
                $specialMessage .= "PCEA Church APP";
            }
            elseif ($totalContributions >= 50000) {
                $specialMessage = "CHAMPION GIVER!\n\n";
                $specialMessage .= "Dear {$member->full_name},\n\n";
                $specialMessage .= "Amazing! You've contributed over KES 50,000! You are truly a blessing to our church!\n\n";
                $specialMessage .= "Your generous heart and faithful giving inspire others and strengthen our community.\n\n";
                $specialMessage .= "May God continue to bless you abundantly!\n\n";
                $specialMessage .= "PCEA Church APP";
            }

            // Send special message if applicable
            if ($specialMessage) {
                // Send with a delay to avoid overwhelming the member
                $this->smsService->sendSms($phoneNumber, $specialMessage);
                
                Log::info('Special congratulatory SMS sent', [
                    'member_id' => $member->id,
                    'total_contributions' => $totalContributions,
                    'contribution_count' => $contributionCount,
                    'message_type' => $contributionCount === 1 ? 'first_time' : 'milestone'
                ]);
            }

        } catch (\Exception $e) {
            Log::error('Special congratulatory SMS error: ' . $e->getMessage(), [
                'member_id' => $member->id,
                'payment_id' => $payment->id
            ]);
        }
    }
}
