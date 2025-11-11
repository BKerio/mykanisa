<?php

namespace App\Http\Controllers;

use App\Models\Contribution;
use App\Models\Member;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ContributionsController extends Controller
{
    /**
     * Get member's contribution summary
     */
    public function getMemberSummary(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 401, 'message' => 'Unauthorized'], 401);
        }

        $member = Member::where('email', $user->email)->first();
        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        $startDate = $request->input('start_date');
        $endDate = $request->input('end_date');

        try {
            $summary = Contribution::getMemberSummary($member->id, $startDate, $endDate);
            $totalContributions = Contribution::getMemberTotalContributions($member->id, $startDate, $endDate);

            return response()->json([
                'status' => 200,
                'summary' => $summary,
                'total_contributions' => $totalContributions,
                'period' => [
                    'start_date' => $startDate,
                    'end_date' => $endDate,
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching member contribution summary', [
                'member_id' => $member->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 500,
                'message' => 'Error fetching contribution summary'
            ], 500);
        }
    }

    /**
     * Get detailed contribution history for a member
     */
    public function getMemberHistory(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 401, 'message' => 'Unauthorized'], 401);
        }

        $member = Member::where('email', $user->email)->first();
        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        $startDate = $request->input('start_date');
        $endDate = $request->input('end_date');
        $accountType = $request->input('account_type');

        try {
            $query = Contribution::where('member_id', $member->id)
                ->with(['payment'])
                ->orderBy('contribution_date', 'desc');

            if ($startDate && $endDate) {
                $query->whereBetween('contribution_date', [$startDate, $endDate]);
            }

        if ($accountType) {
            $query->where('contribution_type', $accountType);
        }

            $contributions = $query->paginate(20);

            return response()->json([
                'status' => 200,
                'contributions' => $contributions
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching member contribution history', [
                'member_id' => $member->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 500,
                'message' => 'Error fetching contribution history'
            ], 500);
        }
    }

    /**
     * Create contributions from payment breakdown
     */
    public function createFromBreakdown(Request $request)
    {
        $request->validate([
            'member_id' => 'required|exists:members,id',
            'payment_id' => 'nullable|exists:payments,id',
            'breakdown' => 'required|array',
            'breakdown.*' => 'required|numeric|min:0',
            'reference' => 'nullable|string|max:50',
        ]);

        try {
            DB::beginTransaction();

            $contributions = [];
            foreach ($request->breakdown as $accountType => $amount) {
                if ($amount > 0) {
                    $contribution = Contribution::create([
                        'member_id' => $request->member_id,
                        'payment_id' => $request->payment_id,
                        'account_type' => $accountType,
                        'amount' => $amount,
                        'reference' => $request->reference,
                        'status' => 'pending',
                    ]);
                    $contributions[] = $contribution;
                }
            }

            DB::commit();

            return response()->json([
                'status' => 200,
                'message' => 'Contributions created successfully',
                'contributions' => $contributions
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error creating contributions from breakdown', [
                'error' => $e->getMessage(),
                'member_id' => $request->member_id,
                'breakdown' => $request->breakdown
            ]);

            return response()->json([
                'status' => 500,
                'message' => 'Error creating contributions'
            ], 500);
        }
    }

    /**
     * Update contribution status
     */
    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:pending,completed,failed'
        ]);

        try {
            $contribution = Contribution::findOrFail($id);
            $contribution->update(['status' => $request->status]);

            return response()->json([
                'status' => 200,
                'message' => 'Contribution status updated successfully',
                'contribution' => $contribution
            ]);
        } catch (\Exception $e) {
            Log::error('Error updating contribution status', [
                'contribution_id' => $id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 500,
                'message' => 'Error updating contribution status'
            ], 500);
        }
    }

    /**
     * Get overall church contribution statistics
     */
    public function getChurchStats(Request $request)
    {
        $startDate = $request->input('start_date');
        $endDate = $request->input('end_date');

        try {
            $query = Contribution::where('status', 'completed');

            if ($startDate && $endDate) {
                $query->whereBetween('contribution_date', [$startDate, $endDate]);
            }

        $stats = $query->selectRaw('
            contribution_type,
            SUM(amount) as total_amount,
            COUNT(*) as contribution_count,
            COUNT(DISTINCT member_id) as unique_contributors
        ')
        ->groupBy('contribution_type')
            ->get();

            $totalAmount = $stats->sum('total_amount');
            $totalContributions = $stats->sum('contribution_count');
            $uniqueContributors = $query->distinct('member_id')->count('member_id');

            return response()->json([
                'status' => 200,
                'stats' => $stats,
                'totals' => [
                    'total_amount' => $totalAmount,
                    'total_contributions' => $totalContributions,
                    'unique_contributors' => $uniqueContributors,
                ],
                'period' => [
                    'start_date' => $startDate,
                    'end_date' => $endDate,
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching church contribution stats', [
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 500,
                'message' => 'Error fetching church statistics'
            ], 500);
        }
    }
}
