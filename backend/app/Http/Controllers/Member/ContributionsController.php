<?php

namespace App\Http\Controllers\Member;

use App\Http\Controllers\Controller;
use App\Models\Contribution;
use Illuminate\Http\Request;

class ContributionsController extends Controller
{
    /**
     * Get member's own contributions
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        // Members can only view their own contributions
        $query = Contribution::where('member_id', $user->id);
        
        // Filter by date range
        if ($request->has('start_date')) {
            $query->where('contribution_date', '>=', $request->input('start_date'));
        }
        if ($request->has('end_date')) {
            $query->where('contribution_date', '<=', $request->input('end_date'));
        }
        
        // Filter by contribution type
        if ($request->has('type')) {
            $query->where('type', $request->input('type'));
        }
        
        $contributions = $query->orderBy('contribution_date', 'desc')
            ->paginate(20);
            
        return response()->json([
            'status' => 200,
            'contributions' => $contributions
        ]);
    }

    /**
     * Get member's contribution statistics
     */
    public function statistics(Request $request)
    {
        $user = $request->user();
        
        // Get member's contribution statistics
        $totalContributions = Contribution::where('member_id', $user->id)->sum('amount');
        $totalCount = Contribution::where('member_id', $user->id)->count();
        $averageContribution = $totalCount > 0 ? $totalContributions / $totalCount : 0;
        
        // Monthly statistics for current year
        $monthlyStats = Contribution::where('member_id', $user->id)
            ->whereYear('contribution_date', now()->year)
            ->selectRaw('MONTH(contribution_date) as month, SUM(amount) as total, COUNT(*) as count')
            ->groupBy('month')
            ->get()
            ->keyBy('month');
            
        // Contribution types breakdown
        $typeBreakdown = Contribution::where('member_id', $user->id)
            ->selectRaw('type, SUM(amount) as total, COUNT(*) as count')
            ->groupBy('type')
            ->get();
            
        // Recent contributions (last 5)
        $recentContributions = Contribution::where('member_id', $user->id)
            ->orderBy('contribution_date', 'desc')
            ->limit(5)
            ->get();
            
        return response()->json([
            'status' => 200,
            'statistics' => [
                'total_amount' => $totalContributions,
                'total_count' => $totalCount,
                'average_amount' => round($averageContribution, 2),
                'monthly_breakdown' => $monthlyStats,
                'type_breakdown' => $typeBreakdown,
                'recent_contributions' => $recentContributions
            ]
        ]);
    }

    /**
     * Get specific contribution details
     */
    public function show(Request $request, Contribution $contribution)
    {
        $user = $request->user();
        
        // Members can only view their own contributions
        if ($contribution->member_id !== $user->id) {
            return response()->json(['message' => 'Access denied'], 403);
        }
        
        return response()->json([
            'status' => 200,
            'contribution' => $contribution
        ]);
    }
}

