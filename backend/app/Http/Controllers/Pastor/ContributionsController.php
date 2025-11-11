<?php

namespace App\Http\Controllers\Pastor;

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
        
        // Get contributions based on pastor's scope
        $query = Contribution::with(['member']);
        
        // Filter by congregation/parish/presbytery
        $congregation = $request->input('congregation');
        $parish = $request->input('parish');
        $presbytery = $request->input('presbytery');
        
        if ($congregation) {
            $query->whereHas('member', function($q) use ($congregation) {
                $q->where('congregation', $congregation);
            });
        }
        if ($parish) {
            $query->whereHas('member', function($q) use ($parish) {
                $q->where('parish', $parish);
            });
        }
        if ($presbytery) {
            $query->whereHas('member', function($q) use ($presbytery) {
                $q->where('presbytery', $presbytery);
            });
        }
        
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
     * Display the specified contribution
     */
    public function show(Request $request, Contribution $contribution)
    {
        $user = $request->user();
        
        // Check if pastor can view this contribution based on member's scope
        $congregation = $request->input('congregation');
        $parish = $request->input('parish');
        $presbytery = $request->input('presbytery');
        
        $member = $contribution->member;
        if ($congregation && $member->congregation !== $congregation) {
            return response()->json(['message' => 'Access denied'], 403);
        }
        
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

        // Verify pastor can create contribution for this member
        $member = Member::findOrFail($validated['member_id']);
        $congregation = $request->input('congregation');
        
        if ($congregation && $member->congregation !== $congregation) {
            return response()->json(['message' => 'Access denied'], 403);
        }
        
        $contribution = Contribution::create($validated);
        $contribution->load('member');
        
        return response()->json([
            'status' => 200,
            'message' => 'Contribution recorded successfully',
            'contribution' => $contribution
        ], 201);
    }

    /**
     * Get contribution statistics for pastor's scope
     */
    public function statistics(Request $request)
    {
        $user = $request->user();
        
        // Base query for contributions in pastor's scope
        $query = Contribution::query();
        
        $congregation = $request->input('congregation');
        $parish = $request->input('parish');
        $presbytery = $request->input('presbytery');
        
        if ($congregation) {
            $query->whereHas('member', function($q) use ($congregation) {
                $q->where('congregation', $congregation);
            });
        }
        
        // Get statistics
        $totalContributions = $query->sum('amount');
        $totalCount = $query->count();
        $averageContribution = $totalCount > 0 ? $totalContributions / $totalCount : 0;
        
        // Monthly statistics for current year
        $monthlyStats = $query->whereYear('contribution_date', now()->year)
            ->selectRaw('MONTH(contribution_date) as month, SUM(amount) as total, COUNT(*) as count')
            ->groupBy('month')
            ->get()
            ->keyBy('month');
            
        // Contribution types breakdown
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

