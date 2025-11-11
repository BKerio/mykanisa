<?php

namespace App\Http\Controllers\Chairman;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Member;
use App\Models\Contribution;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $membersCount = Member::count();
        $contributionsTotal = Contribution::sum('amount');
        return response()->json([
            'members_count' => $membersCount,
            'contributions_total' => $contributionsTotal,
        ]);
    }
}






