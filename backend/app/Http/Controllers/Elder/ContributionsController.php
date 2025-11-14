<?php

namespace App\Http\Controllers\Elder;

use App\Http\Controllers\Controller;
use App\Models\Contribution;
use App\Models\Member;
use Illuminate\Http\Request;

class ContributionsController extends Controller
{
    /**
     * Display a listing of contributions
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        $query = Contribution::with(['member']);
        
        $congregation = $request->input('congregation');
        $parish = $request->input('parish');
        $presbytery = $request->input('presbytery');
        
        if ($congregation) {
            $query->whereHas('member', function($q) use ($congregation) {
                $q->where('congregation', $congregation);
            });
        }
        
        if ($request->has('start_date')) {
            $query->where('contribution_date', '>=', $request->input('start_date'));
        }
        if ($request->has('end_date')) {
            $query->where('contribution_date', '<=', $request->input('end_date'));
        }
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
     * Display the specified contribution
     */
    public function show(Request $request, Contribution $contribution)
    {
        $user = $request->user();
        
        // Elder has full permissions - no scope restrictions
        
        $contribution->load(['member', 'member.dependencies']);
        
        return response()->json([
            'status' => 200,
            'contribution' => $contribution
        ]);
    }

    /**
     * Create a new contribution
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'member_id' => 'required|exists:members,id',
            'type' => 'required|string',
            'amount' => 'required|numeric|min:0',
            'contribution_date' => 'required|date',
            'description' => 'nullable|string',
            'payment_method' => 'nullable|string',
        ]);

        $member = Member::findOrFail($validated['member_id']);
        
        // Elder has full permissions - no scope restrictions
        
        $contribution = Contribution::create($validated);
        $contribution->load('member');
        
        return response()->json([
            'status' => 200,
            'message' => 'Contribution recorded successfully',
            'contribution' => $contribution
        ], 201);
    }

    /**
     * Get contribution statistics
     */
    public function statistics(Request $request)
    {
        $user = $request->user();
        
        $query = Contribution::query();
        
        $congregation = $request->input('congregation');
        
        if ($congregation) {
            $query->whereHas('member', function($q) use ($congregation) {
                $q->where('congregation', $congregation);
            });
        }
        
        $totalContributions = $query->sum('amount');
        $totalCount = $query->count();
        $averageContribution = $totalCount > 0 ? $totalContributions / $totalCount : 0;
        
        $monthlyStats = $query->whereYear('contribution_date', now()->year)
            ->selectRaw('MONTH(contribution_date) as month, SUM(amount) as total, COUNT(*) as count')
            ->groupBy('month')
            ->get()
            ->keyBy('month');
            
        $typeBreakdown = $query->selectRaw('type, SUM(amount) as total, COUNT(*) as count')
            ->groupBy('type')
            ->get();
            
        return response()->json([
            'status' => 200,
            'statistics' => [
                'total_amount' => $totalContributions,
                'total_count' => $totalCount,
                'average_amount' => round($averageContribution, 2),
                'monthly_breakdown' => $monthlyStats,
                'type_breakdown' => $typeBreakdown,
                'scope' => compact('congregation', 'parish', 'presbytery')
            ]
        ]);
    }
}

