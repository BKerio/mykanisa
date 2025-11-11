<?php

namespace App\Http\Controllers;

use App\Models\Region;
use App\Models\Presbytery;
use App\Models\Parish;
use App\Models\Group;
use Illuminate\Http\Request;

class LocationController extends Controller
{
    public function getRegions()
    {
        $regions = Region::orderBy('name')->get(['id','name']);
        return response()->json(['status' => 200, 'regions' => $regions]);
    }

    public function getPresbyteries(Request $request)
    {
        $request->validate([
            'region_id' => 'required|integer|exists:regions,id'
        ]);

        $presbyteries = Presbytery::where('region_id', $request->region_id)
            ->orderBy('name')
            ->get(['id','name']);

        return response()->json(['status' => 200, 'presbyteries' => $presbyteries]);
    }

    public function getParishes(Request $request)
    {
        $request->validate([
            'presbytery_id' => 'required|integer|exists:presbyteries,id'
        ]);

        $parishes = Parish::where('presbytery_id', $request->presbytery_id)
            ->orderBy('name')
            ->get(['id','name']);

        return response()->json(['status' => 200, 'parishes' => $parishes]);
    }

    public function getGroups()
    {
        $groups = Group::orderBy('name')->get(['id','name']);
        return response()->json(['status' => 200, 'groups' => $groups]);
    }
}