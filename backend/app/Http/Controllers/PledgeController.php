<?php

namespace App\Http\Controllers;

use App\Models\Pledge;
use App\Models\Member;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class PledgeController extends Controller
{
    /**
     * Get all pledges for the authenticated member
     */
    public function index(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 401, 'message' => 'Unauthorized'], 401);
        }

        $member = Member::where('email', $user->email)->first();
        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        try {
            $status = $request->input('status'); // active, fulfilled, cancelled, or null for all
            $accountType = $request->input('account_type');

            $query = Pledge::where('member_id', $member->id)
                ->with('member')
                ->orderBy('pledge_date', 'desc');

            if ($status) {
                $query->where('status', $status);
            }

            if ($accountType) {
                $query->where('account_type', $accountType);
            }

            $pledges = $query->get();

            // Calculate summary statistics
            $totalPledged = $pledges->sum('pledge_amount');
            $totalFulfilled = $pledges->sum('fulfilled_amount');
            $totalRemaining = $pledges->sum('remaining_amount');

            return response()->json([
                'status' => 200,
                'pledges' => $pledges,
                'summary' => [
                    'total_pledged' => $totalPledged,
                    'total_fulfilled' => $totalFulfilled,
                    'total_remaining' => $totalRemaining,
                    'fulfillment_percentage' => $totalPledged > 0 ? ($totalFulfilled / $totalPledged) * 100 : 0,
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching pledges', [
                'member_id' => $member->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 500,
                'message' => 'Error fetching pledges'
            ], 500);
        }
    }

    /**
     * Create a new pledge
     */
    public function store(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 401, 'message' => 'Unauthorized'], 401);
        }

        $member = Member::where('email', $user->email)->first();
        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        $validated = $request->validate([
            'account_type' => 'required|string|in:Tithe,Offering,Development,Thanksgiving,FirstFruit,Others',
            'pledge_amount' => 'required|numeric|min:0.01',
            'target_date' => 'nullable|date|after:today',
            'description' => 'nullable|string|max:500',
        ]);

        try {
            DB::beginTransaction();

            $pledge = Pledge::create([
                'member_id' => $member->id,
                'account_type' => $validated['account_type'],
                'pledge_amount' => $validated['pledge_amount'],
                'remaining_amount' => $validated['pledge_amount'],
                'fulfilled_amount' => 0,
                'pledge_date' => now(),
                'target_date' => $validated['target_date'] ?? null,
                'description' => $validated['description'] ?? null,
                'status' => 'active',
            ]);

            DB::commit();

            return response()->json([
                'status' => 201,
                'message' => 'Pledge created successfully',
                'pledge' => $pledge->load('member')
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error creating pledge', [
                'member_id' => $member->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 500,
                'message' => 'Error creating pledge'
            ], 500);
        }
    }

    /**
     * Get a specific pledge
     */
    public function show(Request $request, $id)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 401, 'message' => 'Unauthorized'], 401);
        }

        $member = Member::where('email', $user->email)->first();
        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        try {
            $pledge = Pledge::where('id', $id)
                ->where('member_id', $member->id)
                ->with('member')
                ->first();

            if (!$pledge) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Pledge not found'
                ], 404);
            }

            return response()->json([
                'status' => 200,
                'pledge' => $pledge
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching pledge', [
                'pledge_id' => $id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 500,
                'message' => 'Error fetching pledge'
            ], 500);
        }
    }

    /**
     * Update a pledge
     */
    public function update(Request $request, $id)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 401, 'message' => 'Unauthorized'], 401);
        }

        $member = Member::where('email', $user->email)->first();
        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        $pledge = Pledge::where('id', $id)
            ->where('member_id', $member->id)
            ->first();

        if (!$pledge) {
            return response()->json([
                'status' => 404,
                'message' => 'Pledge not found'
            ], 404);
        }

        // Only allow updating active pledges
        if ($pledge->status !== 'active') {
            return response()->json([
                'status' => 400,
                'message' => 'Can only update active pledges'
            ], 400);
        }

        // Get all request data to check which fields are being updated
        $requestData = $request->all();
        
        // Validate fields individually to handle null values properly
        $rules = [];
        if (array_key_exists('pledge_amount', $requestData)) {
            $rules['pledge_amount'] = 'required|numeric|min:0.01';
        }
        if (array_key_exists('target_date', $requestData)) {
            $rules['target_date'] = 'nullable|date';
        }
        if (array_key_exists('description', $requestData)) {
            $rules['description'] = 'nullable|string|max:500';
        }

        $validated = $request->validate($rules);

        try {
            // If updating pledge amount, adjust remaining amount proportionally
            if (isset($validated['pledge_amount']) && $validated['pledge_amount'] != $pledge->pledge_amount) {
                $oldPledgeAmount = $pledge->pledge_amount;
                $newPledgeAmount = $validated['pledge_amount'];
                
                // Calculate new remaining amount based on fulfillment percentage
                $fulfillmentPercentage = $pledge->getFulfillmentPercentage() / 100;
                $newFulfilledAmount = $newPledgeAmount * $fulfillmentPercentage;
                $newRemainingAmount = $newPledgeAmount - $newFulfilledAmount;
                
                $pledge->pledge_amount = $newPledgeAmount;
                $pledge->fulfilled_amount = $newFulfilledAmount;
                $pledge->remaining_amount = max(0, $newRemainingAmount);
            }

            // Handle target_date - allow clearing by sending null
            if (array_key_exists('target_date', $requestData)) {
                $targetDateValue = $requestData['target_date'];
                if ($targetDateValue === null || $targetDateValue === '') {
                    $pledge->target_date = null;
                } else {
                    // Use validated value if available, otherwise use request value
                    $pledge->target_date = $validated['target_date'] ?? $targetDateValue;
                }
            }

            // Handle description - allow clearing by sending null or empty string
            if (array_key_exists('description', $requestData)) {
                $descriptionValue = $requestData['description'];
                if ($descriptionValue === null || $descriptionValue === '') {
                    $pledge->description = null;
                } else {
                    // Use validated value if available, otherwise use request value
                    $pledge->description = $validated['description'] ?? $descriptionValue;
                }
            }

            $pledge->save();

            return response()->json([
                'status' => 200,
                'message' => 'Pledge updated successfully',
                'pledge' => $pledge->load('member')
            ]);
        } catch (\Exception $e) {
            Log::error('Error updating pledge', [
                'pledge_id' => $id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 500,
                'message' => 'Error updating pledge'
            ], 500);
        }
    }

    /**
     * Cancel a pledge
     */
    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 401, 'message' => 'Unauthorized'], 401);
        }

        $member = Member::where('email', $user->email)->first();
        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        $pledge = Pledge::where('id', $id)
            ->where('member_id', $member->id)
            ->first();

        if (!$pledge) {
            return response()->json([
                'status' => 404,
                'message' => 'Pledge not found'
            ], 404);
        }

        try {
            // Mark as cancelled instead of deleting
            $pledge->status = 'cancelled';
            $pledge->save();

            return response()->json([
                'status' => 200,
                'message' => 'Pledge cancelled successfully'
            ]);
        } catch (\Exception $e) {
            Log::error('Error cancelling pledge', [
                'pledge_id' => $id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 500,
                'message' => 'Error cancelling pledge'
            ], 500);
        }
    }
}

