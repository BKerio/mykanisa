<?php

namespace App\Http\Controllers;

use App\Models\Region;
use App\Models\Presbytery;
use App\Models\Parish;
use Illuminate\Http\Request;

class ChurchStructureController extends Controller
{
    public function regions()
    {
        $regions = Region::orderBy('name')->get(['id','name']);
        return response()->json(['status' => 200, 'regions' => $regions]);
    }

    public function presbyteries(Request $request)
    {
        $request->validate([
            'region_id' => 'required|integer|exists:regions,id',
        ]);
        $presbyteries = Presbytery::where('region_id', $request->region_id)
            ->orderBy('name')
            ->get(['id','name']);
        return response()->json(['status' => 200, 'presbyteries' => $presbyteries]);
    }

    public function parishes(Request $request)
    {
        $request->validate([
            'presbytery_id' => 'required|integer|exists:presbyteries,id',
        ]);
        $parishes = Parish::where('presbytery_id', $request->presbytery_id)
            ->orderBy('name')
            ->get(['id','name']);
        return response()->json(['status' => 200, 'parishes' => $parishes]);
    }
}


