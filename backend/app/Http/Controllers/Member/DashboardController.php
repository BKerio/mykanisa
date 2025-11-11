<?php

namespace App\Http\Controllers\Member;

use App\Http\Controllers\Controller;
use App\Models\Contribution;
use App\Models\Dependency;
use App\Models\Payment;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /**
     * Get member dashboard data
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        // Get member's basic info
        $member = $user->load(['dependencies', 'groups', 'roles']);
        
        // Get contribution statistics
        $totalContributions = Contribution::where('member_id', $user->id)->sum('amount');
        $contributionsCount = Contribution::where('member_id', $user->id)->count();
        $thisMonthContributions = Contribution::where('member_id', $user->id)
            ->whereMonth('contribution_date', now()->month)
            ->whereYear('contribution_date', now()->year)
            ->sum('amount');
            
        // Get payment statistics
        $totalPayments = Payment::where('member_id', $user->id)->sum('amount');
        $paymentsCount = Payment::where('member_id', $user->id)->count();
        $thisMonthPayments = Payment::where('member_id', $user->id)
            ->whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)
            ->sum('amount');
            
        // Get dependents count
        $dependentsCount = Dependency::where('member_id', $user->id)->count();
        
        // Get recent contributions (last 5)
        $recentContributions = Contribution::where('member_id', $user->id)
            ->orderBy('contribution_date', 'desc')
            ->limit(5)
            ->get();
            
        // Get recent payments (last 5)
        $recentPayments = Payment::where('member_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();
            
        // Get monthly contribution trend (last 6 months)
        $monthlyTrend = Contribution::where('member_id', $user->id)
            ->where('contribution_date', '>=', now()->subMonths(6))
            ->selectRaw('DATE_FORMAT(contribution_date, "%Y-%m") as month, SUM(amount) as total')
            ->groupBy('month')
            ->orderBy('month')
            ->get()
            ->keyBy('month');
            
        // Get contribution types breakdown
        $contributionTypes = Contribution::where('member_id', $user->id)
            ->selectRaw('type, SUM(amount) as total, COUNT(*) as count')
            ->groupBy('type')
            ->get();
            
        return response()->json([
            'status' => 200,
            'dashboard' => [
                'member' => $member,
                'statistics' => [
                    'contributions' => [
                        'total_amount' => $totalContributions,
                        'total_count' => $contributionsCount,
                        'this_month' => $thisMonthContributions,
                    ],
                    'payments' => [
                        'total_amount' => $totalPayments,
                        'total_count' => $paymentsCount,
                        'this_month' => $thisMonthPayments,
                    ],
                    'dependents_count' => $dependentsCount,
                ],
                'recent_activity' => [
                    'contributions' => $recentContributions,
                    'payments' => $recentPayments,
                ],
                'trends' => [
                    'monthly_contributions' => $monthlyTrend,
                    'contribution_types' => $contributionTypes,
                ]
            ]
        ]);
    }

    /**
     * Get member's notifications/alerts and messages from elders
     */
    public function notifications(Request $request)
    {
        // Notifications table has been removed
        // Return empty notifications array
        return response()->json([
            'status' => 200,
            'notifications' => [],
            'message' => 'Notifications feature is currently unavailable'
        ]);
    }

    /**
     * Get member's upcoming events
     */
    public function events(Request $request)
    {
        $user = $request->user();
        
        // This would typically come from an events table
        // For now, return some mock events
        $events = [
            [
                'id' => 1,
                'title' => 'Sunday Service',
                'date' => now()->nextSunday()->format('Y-m-d'),
                'time' => '10:00',
                'location' => 'Main Sanctuary',
                'type' => 'service',
            ],
            [
                'id' => 2,
                'title' => 'Bible Study',
                'date' => now()->nextWednesday()->format('Y-m-d'),
                'time' => '19:00',
                'location' => 'Church Library',
                'type' => 'study',
            ],
        ];
        
        return response()->json([
            'status' => 200,
            'events' => $events
        ]);
    }
}

