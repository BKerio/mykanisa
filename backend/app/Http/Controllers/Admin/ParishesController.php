<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Parish;
use App\Models\Presbytery;
use Illuminate\Support\Facades\DB;

class ParishesController extends Controller
{
    /**
     * Get all parishes with pagination and search
     */
    public function index(Request $request)
    {
        $query = Parish::with(['presbytery.region'])->orderBy('name');
        
        // Filter by presbytery if provided
        if ($presbyteryId = $request->query('presbytery_id')) {
            $query->where('presbytery_id', $presbyteryId);
        }
        
        // Filter by region if provided
        if ($regionId = $request->query('region_id')) {
            $query->whereHas('presbytery', function($q) use ($regionId) {
                $q->where('region_id', $regionId);
            });
        }
        
        if ($search = $request->query('q')) {
            $query->where('name', 'like', "%{$search}%");
        }
        
        $parishes = $query->paginate($request->integer('per_page', 20));
        
        return response()->json($parishes);
    }

    /**
     * Create a new parish
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'presbytery_id' => 'required|exists:presbyteries,id',
            'name' => 'required|string|max:255',
        ]);

        // Check for unique name within the presbytery
        $exists = Parish::where('presbytery_id', $validated['presbytery_id'])
            ->where('name', $validated['name'])
            ->exists();

        if ($exists) {
            return response()->json([
                'status' => 400,
                'message' => 'A parish with this name already exists in this presbytery.'
            ], 400);
        }

        try {
            $parish = Parish::create($validated);
            $parish->load(['presbytery.region']);
            
            return response()->json([
                'status' => 201,
                'message' => 'Parish created successfully',
                'parish' => $parish
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error creating parish: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get a specific parish
     */
    public function show(Parish $parish)
    {
        $parish->load(['presbytery.region']);
        return response()->json([
            'status' => 200,
            'parish' => $parish
        ]);
    }

    /**
     * Update a parish
     */
    public function update(Request $request, Parish $parish)
    {
        $validated = $request->validate([
            'presbytery_id' => 'sometimes|exists:presbyteries,id',
            'name' => 'sometimes|string|max:255',
        ]);

        // Check for unique name within the presbytery if name or presbytery_id is being updated
        if (isset($validated['name']) || isset($validated['presbytery_id'])) {
            $presbyteryId = $validated['presbytery_id'] ?? $parish->presbytery_id;
            $name = $validated['name'] ?? $parish->name;
            
            $exists = Parish::where('presbytery_id', $presbyteryId)
                ->where('name', $name)
                ->where('id', '!=', $parish->id)
                ->exists();

            if ($exists) {
                return response()->json([
                    'status' => 400,
                    'message' => 'A parish with this name already exists in this presbytery.'
                ], 400);
            }
        }

        try {
            $parish->update($validated);
            $parish->load(['presbytery.region']);
            
            return response()->json([
                'status' => 200,
                'message' => 'Parish updated successfully',
                'parish' => $parish
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error updating parish: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete a parish
     */
    public function destroy(Parish $parish)
    {
        try {
            $parish->delete();
            
            return response()->json([
                'status' => 200,
                'message' => 'Parish deleted successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error deleting parish: ' . $e->getMessage()
            ], 500);
        }
    }
}

