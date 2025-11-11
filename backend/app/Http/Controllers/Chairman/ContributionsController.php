<?php

namespace App\Http\Controllers\Chairman;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Contribution;

class ContributionsController extends Controller
{
    public function index(Request $request)
    {
        $contributions = Contribution::query()->latest()->paginate(20);
        return response()->json($contributions);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'member_id' => 'required|exists:members,id',
            'amount' => 'required|numeric|min:0',
            'type' => 'required|string|max:100',
            'notes' => 'nullable|string',
        ]);

        $contribution = Contribution::create($validated);
        return response()->json(['status' => 201, 'contribution' => $contribution]);
    }

    public function show(Contribution $contribution)
    {
        return response()->json($contribution);
    }

    public function statistics()
    {
        $total = Contribution::sum('amount');
        $count = Contribution::count();
        return response()->json(['total' => $total, 'count' => $count]);
    }
}






