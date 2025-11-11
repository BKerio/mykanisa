<?php

namespace App\Http\Controllers\Treasurer;

use App\Http\Controllers\Controller;
use App\Models\Contribution;
use App\Models\Payment;
use Illuminate\Http\Request;

class FinancialController extends Controller
{
    /**
     * Get comprehensive financial overview
     */
    public function overview(Request $request)
    {
        $user = $request->user();
        
        $congregation = $request->input('congregation');
        
        // Base queries
        $contributionsQuery = Contribution::query();
        $paymentsQuery = Payment::query();
        
        if ($congregation) {
            $contributionsQuery->whereHas('member', function($q) use ($congregation) {
                $q->where('congregation', $congregation);
            });
            
            $paymentsQuery->whereHas('member', function($q) use ($congregation) {
                $q->where('congregation', $congregation);
            });
        }
        
        // Current month statistics
        $currentMonth = now()->format('Y-m');
        $currentMonthContributions = $contributionsQuery->clone()
            ->whereRaw("DATE_FORMAT(contribution_date, '%Y-%m') = ?", [$currentMonth])
            ->sum('amount');
            
        $currentMonthPayments = $paymentsQuery->clone()
            ->whereRaw("DATE_FORMAT(created_at, '%Y-%m') = ?", [$currentMonth])
            ->sum('amount');
        
        // Yearly statistics
        $currentYear = now()->year;
        $yearlyContributions = $contributionsQuery->clone()
            ->whereYear('contribution_date', $currentYear)
            ->sum('amount');
            
        $yearlyPayments = $paymentsQuery->clone()
            ->whereYear('created_at', $currentYear)
            ->sum('amount');
        
        // Monthly breakdown for current year
        $monthlyBreakdown = $contributionsQuery->clone()
            ->whereYear('contribution_date', $currentYear)
            ->selectRaw('MONTH(contribution_date) as month, SUM(amount) as contributions')
            ->groupBy('month')
            ->get()
            ->keyBy('month');
            
        $monthlyPayments = $paymentsQuery->clone()
            ->whereYear('created_at', $currentYear)
            ->selectRaw('MONTH(created_at) as month, SUM(amount) as payments')
            ->groupBy('month')
            ->get()
            ->keyBy('month');
        
        // Contribution types breakdown
        $contributionTypes = $contributionsQuery->clone()
            ->selectRaw('type, SUM(amount) as total, COUNT(*) as count')
            ->groupBy('type')
            ->get();
            
        return response()->json([
            'status' => 200,
            'overview' => [
                'current_month' => [
                    'contributions' => $currentMonthContributions,
                    'payments' => $currentMonthPayments,
                    'net' => $currentMonthContributions - $currentMonthPayments
                ],
                'yearly' => [
                    'contributions' => $yearlyContributions,
                    'payments' => $yearlyPayments,
                    'net' => $yearlyContributions - $yearlyPayments
                ],
                'monthly_breakdown' => $monthlyBreakdown,
                'monthly_payments' => $monthlyPayments,
                'contribution_types' => $contributionTypes,
                'scope' => compact('congregation')
            ]
        ]);
    }

    /**
     * Get detailed financial reports
     */
    public function reports(Request $request)
    {
        $user = $request->user();
        
        $congregation = $request->input('congregation');
        $startDate = $request->input('start_date', now()->startOfMonth());
        $endDate = $request->input('end_date', now()->endOfMonth());
        
        $contributionsQuery = Contribution::with(['member'])
            ->whereBetween('contribution_date', [$startDate, $endDate]);
            
        $paymentsQuery = Payment::with(['member'])
            ->whereBetween('created_at', [$startDate, $endDate]);
        
        if ($congregation) {
            $contributionsQuery->whereHas('member', function($q) use ($congregation) {
                $q->where('congregation', $congregation);
            });
            
            $paymentsQuery->whereHas('member', function($q) use ($congregation) {
                $q->where('congregation', $congregation);
            });
        }
        
        $contributions = $contributionsQuery->orderBy('contribution_date', 'desc')->get();
        $payments = $paymentsQuery->orderBy('created_at', 'desc')->get();
        
        return response()->json([
            'status' => 200,
            'reports' => [
                'contributions' => $contributions,
                'payments' => $payments,
                'summary' => [
                    'total_contributions' => $contributions->sum('amount'),
                    'total_payments' => $payments->sum('amount'),
                    'net_amount' => $contributions->sum('amount') - $payments->sum('amount'),
                    'period' => [
                        'start' => $startDate,
                        'end' => $endDate
                    ]
                ]
            ]
        ]);
    }

    /**
     * Get financial transactions
     */
    public function transactions(Request $request)
    {
        $user = $request->user();
        
        $congregation = $request->input('congregation');
        $type = $request->input('type', 'all'); // all, contributions, payments
        
        $contributionsQuery = Contribution::with(['member'])
            ->when($congregation, function($q) use ($congregation) {
                return $q->whereHas('member', function($subQ) use ($congregation) {
                    $subQ->where('congregation', $congregation);
                });
            });
            
        $paymentsQuery = Payment::with(['member'])
            ->when($congregation, function($q) use ($congregation) {
                return $q->whereHas('member', function($subQ) use ($congregation) {
                    $subQ->where('congregation', $congregation);
                });
            });
        
        switch ($type) {
            case 'contributions':
                $transactions = $contributionsQuery->orderBy('contribution_date', 'desc')->paginate(20);
                break;
            case 'payments':
                $transactions = $paymentsQuery->orderBy('created_at', 'desc')->paginate(20);
                break;
            default:
                // Combine both types
                $contributions = $contributionsQuery->get()->map(function($item) {
                    return [
                        'id' => 'c_' . $item->id,
                        'type' => 'contribution',
                        'amount' => $item->amount,
                        'date' => $item->contribution_date,
                        'description' => $item->type . ' - ' . ($item->description ?? ''),
                        'member' => $item->member->full_name,
                        'created_at' => $item->created_at
                    ];
                });
                
                $payments = $paymentsQuery->get()->map(function($item) {
                    return [
                        'id' => 'p_' . $item->id,
                        'type' => 'payment',
                        'amount' => $item->amount,
                        'date' => $item->created_at->format('Y-m-d'),
                        'description' => 'Payment - ' . ($item->description ?? ''),
                        'member' => $item->member->full_name,
                        'created_at' => $item->created_at
                    ];
                });
                
                $allTransactions = $contributions->concat($payments)
                    ->sortByDesc('created_at')
                    ->values();
                
                $transactions = $this->paginate($allTransactions, 20);
        }
        
        return response()->json([
            'status' => 200,
            'transactions' => $transactions
        ]);
    }

    /**
     * Simple pagination helper for collections
     */
    private function paginate($items, $perPage)
    {
        $currentPage = request()->get('page', 1);
        $offset = ($currentPage - 1) * $perPage;
        $itemsForCurrentPage = $items->slice($offset, $perPage)->values();
        
        return new \Illuminate\Pagination\LengthAwarePaginator(
            $itemsForCurrentPage,
            $items->count(),
            $perPage,
            $currentPage,
            ['path' => request()->url()]
        );
    }
}

