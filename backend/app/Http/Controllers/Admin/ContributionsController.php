<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\Member;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ContributionsController extends Controller
{
    /**
     * Display a listing of payments (contributions) with optional filtering by congregation
     */
    public function index(Request $request)
    {
        $perPage = (int)($request->query('per_page', 20));
        $congregation = $request->query('congregation');
        $status = $request->query('status');
        $dateFrom = $request->query('date_from');
        $dateTo = $request->query('date_to');
        $search = trim((string)$request->query('q', ''));

        $query = Payment::with(['member:id,full_name,e_kanisa_number,congregation,district,parish,presbytery,region']);

        // Filter by congregation
        if ($congregation) {
            $query->whereHas('member', function($q) use ($congregation) {
                $q->where('congregation', 'like', "%{$congregation}%");
            });
        }

        // Filter by status
        if ($status) {
            $query->where('status', $status);
        }

        // Filter by date range
        if ($dateFrom) {
            $query->where('created_at', '>=', $dateFrom);
        }
        if ($dateTo) {
            $query->where('created_at', '<=', $dateTo);
        }

        // Search functionality
        if ($search !== '') {
            $query->where(function($q) use ($search) {
                $q->where('mpesa_receipt_number', 'like', "%{$search}%")
                  ->orWhere('account_reference', 'like', "%{$search}%")
                  ->orWhereHas('member', function($memberQuery) use ($search) {
                      $memberQuery->where('full_name', 'like', "%{$search}%")
                                 ->orWhere('e_kanisa_number', 'like', "%{$search}%");
                  });
            });
        }

        $payments = $query->orderByDesc('created_at')
                         ->paginate($perPage);

        return response()->json($payments);
    }

    /**
     * Get payments grouped by congregation
     */
    public function byCongregation(Request $request)
    {
        $dateFrom = $request->query('date_from');
        $dateTo = $request->query('date_to');
        $congregation = $request->query('congregation');

        $query = Payment::with(['member:id,full_name,e_kanisa_number,congregation,district,parish,presbytery,region'])
                        ->where('status', 'confirmed');
        // Filter by congregation (optional)
        if ($congregation) {
            $query->whereHas('member', function($q) use ($congregation) {
                $q->where('congregation', $congregation);
            });
        }

        // Filter by date range
        if ($dateFrom) {
            $query->where('created_at', '>=', $dateFrom);
        }
        if ($dateTo) {
            $query->where('created_at', '<=', $dateTo);
        }

        $payments = $query->get();

        // Group by congregation
        $grouped = $payments->groupBy('member.congregation')->map(function ($congregationPayments, $congregationName) {
            return [
                'congregation' => $congregationName,
                'total_amount' => $congregationPayments->sum('amount'),
                'total_contributions' => $congregationPayments->count(),
                'contributions' => $congregationPayments->map(function ($payment) {
                    return [
                        'id' => $payment->id,
                        'member_name' => $payment->member->full_name,
                        'e_kanisa_number' => $payment->member->e_kanisa_number,
                        'amount' => $payment->amount,
                        'mpesa_receipt_number' => $payment->mpesa_receipt_number,
                        'account_reference' => $payment->account_reference,
                        'created_at' => $payment->created_at,
                        'status' => $payment->status,
                    ];
                }),
            ];
        });

        return response()->json([
            'congregations' => $grouped->values(),
            'summary' => [
                'total_congregations' => $grouped->count(),
                'total_amount' => $payments->sum('amount'),
                'total_contributions' => $payments->count(),
            ]
        ]);
    }

    /**
     * Get payment statistics
     */
    public function statistics(Request $request)
    {
        $dateFrom = $request->query('date_from');
        $dateTo = $request->query('date_to');
        $congregation = $request->query('congregation');

        $query = Payment::where('status', 'confirmed');

        // Filter by date range
        if ($dateFrom) {
            $query->where('created_at', '>=', $dateFrom);
        }
        if ($dateTo) {
            $query->where('created_at', '<=', $dateTo);
        }

        // Filter by congregation
        if ($congregation) {
            $query->whereHas('member', function($q) use ($congregation) {
                $q->where('congregation', 'like', "%{$congregation}%");
            });
        }

        $payments = $query->get();

        // Statistics by congregation
        $byCongregation = $payments->groupBy('member.congregation')->map(function ($congregationPayments) {
            return [
                'congregation' => $congregationPayments->first()->member->congregation,
                'count' => $congregationPayments->count(),
                'total_amount' => $congregationPayments->sum('amount'),
                'average_amount' => $congregationPayments->avg('amount'),
            ];
        });

        // Monthly statistics
        $monthly = $payments->groupBy(function ($payment) {
            return $payment->created_at->format('Y-m');
        })->map(function ($monthPayments) {
            return [
                'month' => $monthPayments->first()->created_at->format('Y-m'),
                'count' => $monthPayments->count(),
                'total_amount' => $monthPayments->sum('amount'),
            ];
        });

        return response()->json([
            'overview' => [
                'total_contributions' => $payments->count(),
                'total_amount' => $payments->sum('amount'),
                'average_contribution' => $payments->avg('amount'),
            ],
            'by_congregation' => $byCongregation->values(),
            'monthly' => $monthly->values(),
        ]);
    }

    /**
     * Display the specified payment
     */
    public function show(Payment $payment)
    {
        $payment->load(['member:id,full_name,e_kanisa_number,congregation,district,parish,presbytery,region,telephone,email']);
        return response()->json($payment);
    }

    /**
     * Get list of unique congregations
     */
    public function congregations()
    {
        $congregations = Member::select('congregation')
                              ->distinct()
                              ->orderBy('congregation')
                              ->pluck('congregation');

        return response()->json($congregations);
    }

    /**
     * Get payment types based on account reference patterns
     */
    public function types()
    {
        $types = [
            'Tithe',
            'Offering',
            'Development',
            'Thanksgiving',
            'FirstFruit',
            'Others',
        ];

        return response()->json($types);
    }

    /**
     * Get all unique congregations with their church structure
     */
    public function congregationsWithLocations()
    {
        $rows = Member::query()
            ->select('congregation', 'district', 'parish', 'presbytery', 'region')
            ->whereNotNull('congregation')
            ->where('congregation', '!=', '')
            ->groupBy('congregation', 'district', 'parish', 'presbytery', 'region')
            ->orderBy('congregation')
            ->get();

        return response()->json($rows);
    }

    /**
     * Get total contributions amount (and count) with optional filters
     */
    public function total(Request $request)
    {
        $dateFrom = $request->query('date_from');
        $dateTo = $request->query('date_to');
        $congregation = $request->query('congregation');
        $county = $request->query('county');
        $subcounty = $request->query('subcounty');
        $contributionType = $request->query('type');

        $query = Contribution::query()
            ->where('status', 'completed')
            ->with(['member:id,region,presbytery,parish,district,congregation']);

        // Filters on member church structure and congregation
        if ($county) {
            $query->whereHas('member', function($q) use ($county) {
                $q->where('region', $county);
            });
        }
        if ($subcounty) {
            $query->whereHas('member', function($q) use ($subcounty) {
                $q->where('presbytery', $subcounty);
            });
        }
        if ($congregation) {
            $query->whereHas('member', function($q) use ($congregation) {
                $q->where('congregation', $congregation);
            });
        }

        // Date range
        if ($dateFrom) {
            $query->where('contribution_date', '>=', $dateFrom);
        }
        if ($dateTo) {
            $query->where('contribution_date', '<=', $dateTo);
        }

        // Type (case-insensitive)
        if ($contributionType) {
            $query->whereRaw('LOWER(contribution_type) = ?', [strtolower($contributionType)]);
        }

        $totalAmount = (float) $query->sum('amount');
        $totalCount = (int) $query->count();

        return response()->json([
            'total_amount' => $totalAmount,
            'total_contributions' => $totalCount,
        ]);
    }
}
