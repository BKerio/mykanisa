<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Presbytery;
use App\Models\Region;
use Illuminate\Support\Facades\DB;

class PresbyteriesController extends Controller
{
    /**
     * Get all presbyteries with pagination and search
     */
    public function index(Request $request)
    {
        $query = Presbytery::with(['region'])->withCount('parishes')->orderBy('name');
        
        // Filter by region if provided
        if ($regionId = $request->query('region_id')) {
            $query->where('region_id', $regionId);
        }
        
        if ($search = $request->query('q')) {
            $query->where('name', 'like', "%{$search}%");
        }
        
        $presbyteries = $query->paginate($request->integer('per_page', 20));
        
        return response()->json($presbyteries);
    }

    /**
     * Create a new presbytery
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'region_id' => 'required|exists:regions,id',
            'name' => 'required|string|max:255',
        ]);

        // Check for unique name within the region
        $exists = Presbytery::where('region_id', $validated['region_id'])
            ->where('name', $validated['name'])
            ->exists();

        if ($exists) {
            return response()->json([
                'status' => 400,
                'message' => 'A presbytery with this name already exists in this region.'
            ], 400);
        }

        try {
            $presbytery = Presbytery::create($validated);
            $presbytery->load(['region']);
            $presbytery->loadCount('parishes');
            
            return response()->json([
                'status' => 201,
                'message' => 'Presbytery created successfully',
                'presbytery' => $presbytery
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error creating presbytery: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get a specific presbytery
     */
    public function show(Presbytery $presbytery)
    {
        $presbytery->load(['region']);
        $presbytery->loadCount('parishes');
        return response()->json([
            'status' => 200,
            'presbytery' => $presbytery
        ]);
    }

    /**
     * Update a presbytery
     */
    public function update(Request $request, Presbytery $presbytery)
    {
        $validated = $request->validate([
            'region_id' => 'sometimes|exists:regions,id',
            'name' => 'sometimes|string|max:255',
        ]);

        // Check for unique name within the region if name or region_id is being updated
        if (isset($validated['name']) || isset($validated['region_id'])) {
            $regionId = $validated['region_id'] ?? $presbytery->region_id;
            $name = $validated['name'] ?? $presbytery->name;
            
            $exists = Presbytery::where('region_id', $regionId)
                ->where('name', $name)
                ->where('id', '!=', $presbytery->id)
                ->exists();

            if ($exists) {
                return response()->json([
                    'status' => 400,
                    'message' => 'A presbytery with this name already exists in this region.'
                ], 400);
            }
        }

        try {
            $presbytery->update($validated);
            $presbytery->load(['region']);
            $presbytery->loadCount('parishes');
            
            return response()->json([
                'status' => 200,
                'message' => 'Presbytery updated successfully',
                'presbytery' => $presbytery
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error updating presbytery: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete a presbytery
     * Note: This will cascade delete all parishes under this presbytery
     */
    public function destroy(Presbytery $presbytery)
    {
        try {
            // Load parishes to count them
            $presbytery->load('parishes');
            $parishCount = $presbytery->parishes->count();
            
            // Delete the presbytery - database cascade will handle parishes
            $presbytery->delete();
            
            $message = 'Presbytery deleted successfully';
            if ($parishCount > 0) {
                $message .= ". Deleted {$parishCount} parish" . ($parishCount !== 1 ? 'ies' : '') . ".";
            }
            
            return response()->json([
                'status' => 200,
                'message' => $message,
                'deleted_counts' => [
                    'parishes' => $parishCount,
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error deleting presbytery: ' . $e->getMessage()
            ], 500);
        }
    }
}

