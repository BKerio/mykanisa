<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Permission;
use Illuminate\Http\Request;

class PermissionsController extends Controller
{
    /**
     * Display a listing of permissions
     */
    public function index(Request $request)
    {
        $query = Permission::with('roles');

        // Search
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('slug', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        $permissions = $query->orderBy('name')->paginate(50);

        return response()->json([
            'status' => 200,
            'permissions' => $permissions
        ]);
    }

    /**
     * Store a newly created permission
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'slug' => 'required|string|max:255|unique:permissions,slug',
            'description' => 'nullable|string'
        ]);

        $permission = Permission::create($validated);

        return response()->json([
            'status' => 201,
            'message' => 'Permission created successfully',
            'permission' => $permission
        ], 201);
    }

    /**
     * Display the specified permission
     */
    public function show(Permission $permission)
    {
        $permission->load('roles');

        return response()->json([
            'status' => 200,
            'permission' => $permission
        ]);
    }

    /**
     * Update the specified permission
     */
    public function update(Request $request, Permission $permission)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'slug' => 'required|string|max:255|unique:permissions,slug,' . $permission->id,
            'description' => 'nullable|string'
        ]);

        $permission->update($validated);

        return response()->json([
            'status' => 200,
            'message' => 'Permission updated successfully',
            'permission' => $permission
        ]);
    }

    /**
     * Remove the specified permission
     */
    public function destroy(Permission $permission)
    {
        // Check if permission is assigned to any roles
        $roleCount = $permission->roles()->count();
        if ($roleCount > 0) {
            return response()->json([
                'status' => 409,
                'message' => "Cannot delete permission. It is currently assigned to {$roleCount} role(s)"
            ], 409);
        }

        $permission->delete();

        return response()->json([
            'status' => 200,
            'message' => 'Permission deleted successfully'
        ]);
    }
}

