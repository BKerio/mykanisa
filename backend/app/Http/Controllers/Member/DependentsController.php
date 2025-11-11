<?php

namespace App\Http\Controllers\Member;

use App\Http\Controllers\Controller;
use App\Models\Dependency;
use Illuminate\Http\Request;

class DependentsController extends Controller
{
    /**
     * Get member's dependents
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        // Members can only view their own dependents
        $dependents = Dependency::where('member_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get();
            
        return response()->json([
            'status' => 200,
            'dependents' => $dependents
        ]);
    }

    /**
     * Add a new dependent
     */
    public function store(Request $request)
    {
        $user = $request->user();
        
        $validated = $request->validate([
            'full_name' => 'required|string|max:255',
            'relationship' => 'required|string|max:255',
            'date_of_birth' => 'required|date',
            'gender' => 'required|in:male,female',
            'is_school_going' => 'sometimes|boolean',
            'school_name' => 'nullable|string|max:255',
        ]);

        $validated['member_id'] = $user->id;
        
        $dependent = Dependency::create($validated);
        
        return response()->json([
            'status' => 200,
            'message' => 'Dependent added successfully',
            'dependent' => $dependent
        ], 201);
    }

    /**
     * Update a dependent
     */
    public function update(Request $request, Dependency $dependency)
    {
        $user = $request->user();
        
        // Members can only update their own dependents
        if ($dependency->member_id !== $user->id) {
            return response()->json(['message' => 'Access denied'], 403);
        }
        
        $validated = $request->validate([
            'full_name' => 'sometimes|string|max:255',
            'relationship' => 'sometimes|string|max:255',
            'date_of_birth' => 'sometimes|date',
            'gender' => 'sometimes|in:male,female',
            'is_school_going' => 'sometimes|boolean',
            'school_name' => 'nullable|string|max:255',
        ]);

        $dependency->update($validated);
        
        return response()->json([
            'status' => 200,
            'message' => 'Dependent updated successfully',
            'dependent' => $dependency
        ]);
    }

    /**
     * Delete a dependent
     */
    public function destroy(Request $request, Dependency $dependency)
    {
        $user = $request->user();
        
        // Members can only delete their own dependents
        if ($dependency->member_id !== $user->id) {
            return response()->json(['message' => 'Access denied'], 403);
        }
        
        $dependency->delete();
        
        return response()->json([
            'status' => 200,
            'message' => 'Dependent deleted successfully'
        ]);
    }
}

