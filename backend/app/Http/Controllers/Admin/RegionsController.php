<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Region;
use Illuminate\Support\Facades\DB;

class RegionsController extends Controller
{
    /**
     * Get all regions with pagination and search
     */
    public function index(Request $request)
    {
        $query = Region::withCount('presbyteries')->orderBy('name');
        
        if ($search = $request->query('q')) {
            $query->where('name', 'like', "%{$search}%");
        }
        
        $regions = $query->paginate($request->integer('per_page', 20));
        
        return response()->json($regions);
    }

    /**
     * Create a new region
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:regions,name',
        ]);

        try {
            $region = Region::create($validated);
            $region->loadCount('presbyteries');
            
            return response()->json([
                'status' => 201,
                'message' => 'Region created successfully',
                'region' => $region
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error creating region: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get a specific region with its presbyteries and parishes
     */
    public function show(Region $region)
    {
        $region->load(['presbyteries.parishes']);
        $region->loadCount('presbyteries');
        
        // Count total parishes
        $totalParishes = 0;
        foreach ($region->presbyteries as $presbytery) {
            $totalParishes += $presbytery->parishes->count();
        }
        
        return response()->json([
            'status' => 200,
            'region' => $region,
            'statistics' => [
                'presbyteries_count' => $region->presbyteries->count(),
                'parishes_count' => $totalParishes,
            ]
        ]);
    }

    /**
     * Update a region
     */
    public function update(Request $request, Region $region)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:regions,name,' . $region->id,
        ]);

        try {
            $region->update($validated);
            $region->loadCount('presbyteries');
            
            return response()->json([
                'status' => 200,
                'message' => 'Region updated successfully',
                'region' => $region
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error updating region: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete a region
     * Note: This will cascade delete all presbyteries and parishes under this region
     */
    public function destroy(Region $region)
    {
        try {
            // Load presbyteries with parishes to count everything
            $region->load('presbyteries.parishes');
            
            $presbyteryCount = $region->presbyteries->count();
            
            // Calculate total parishes that will be deleted
            $parishCount = 0;
            foreach ($region->presbyteries as $presbytery) {
                $parishCount += $presbytery->parishes->count();
            }
            
            // Delete the region - database cascade will handle presbyteries and parishes
            $region->delete();
            
            $message = 'Region deleted successfully';
            if ($presbyteryCount > 0 || $parishCount > 0) {
                $message .= " Deleted {$presbyteryCount} presbytery" . ($presbyteryCount !== 1 ? 'ies' : '') . 
                           " and {$parishCount} parish" . ($parishCount !== 1 ? 'ies' : '') . ".";
            }
            
            return response()->json([
                'status' => 200,
                'message' => $message,
                'deleted_counts' => [
                    'presbyteries' => $presbyteryCount,
                    'parishes' => $parishCount,
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error deleting region: ' . $e->getMessage()
            ], 500);
        }
    }
}

