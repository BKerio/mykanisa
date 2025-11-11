<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Role;
use App\Models\Permission;
use App\Models\Member;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class RolesController extends Controller
{
    /**
     * Display a listing of roles
     */
    public function index(Request $request)
    {
        $query = Role::with('permissions');

        // Filter by type
        if ($request->has('type')) {
            if ($request->type === 'system') {
                $query->systemRoles();
            } elseif ($request->type === 'custom') {
                $query->customRoles();
            }
        }

        // Search
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        $roles = $query->orderBy('hierarchy_level', 'desc')
                      ->orderBy('name')
                      ->paginate(20);

        return response()->json([
            'status' => 200,
            'roles' => $roles
        ]);
    }

    /**
     * Store a newly created role
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'slug' => 'required|string|max:255|unique:roles,slug',
            'description' => 'nullable|string',
            'is_system_role' => 'boolean',
            'hierarchy_level' => 'integer|min:0|max:100',
            'permissions' => 'array',
            'permissions.*' => 'string|exists:permissions,slug'
        ]);

        $role = Role::create([
            'name' => $validated['name'],
            'slug' => $validated['slug'],
            'description' => $validated['description'] ?? null,
            'is_system_role' => $validated['is_system_role'] ?? false,
            'hierarchy_level' => $validated['hierarchy_level'] ?? 0,
        ]);

        // Attach permissions
        if (isset($validated['permissions'])) {
            $role->syncPermissions($validated['permissions']);
        }

        $role->load('permissions');

        return response()->json([
            'status' => 201,
            'message' => 'Role created successfully',
            'role' => $role
        ], 201);
    }

    /**
     * Display the specified role
     */
    public function show(Role $role)
    {
        $role->load(['permissions', 'members' => function($query) {
            $query->wherePivot('is_active', true)
                  ->withPivot(['congregation', 'parish', 'presbytery', 'assigned_at', 'expires_at']);
        }]);

        return response()->json([
            'status' => 200,
            'role' => $role
        ]);
    }

    /**
     * Update the specified role
     */
    public function update(Request $request, Role $role)
    {
        // Prevent modification of system roles
        if ($role->is_system_role) {
            return response()->json([
                'status' => 403,
                'message' => 'System roles cannot be modified'
            ], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'slug' => ['required', 'string', 'max:255', Rule::unique('roles', 'slug')->ignore($role->id)],
            'description' => 'nullable|string',
            'hierarchy_level' => 'integer|min:0|max:100',
            'permissions' => 'array',
            'permissions.*' => 'string|exists:permissions,slug'
        ]);

        $role->update([
            'name' => $validated['name'],
            'slug' => $validated['slug'],
            'description' => $validated['description'] ?? null,
            'hierarchy_level' => $validated['hierarchy_level'] ?? $role->hierarchy_level,
        ]);

        // Update permissions
        if (isset($validated['permissions'])) {
            $role->syncPermissions($validated['permissions']);
        }

        $role->load('permissions');

        return response()->json([
            'status' => 200,
            'message' => 'Role updated successfully',
            'role' => $role
        ]);
    }

    /**
     * Remove the specified role
     */
    public function destroy(Role $role)
    {
        // Prevent deletion of system roles
        if ($role->is_system_role) {
            return response()->json([
                'status' => 403,
                'message' => 'System roles cannot be deleted'
            ], 403);
        }

        // Check if role is assigned to any members
        $memberCount = $role->members()->wherePivot('is_active', true)->count();
        if ($memberCount > 0) {
            return response()->json([
                'status' => 409,
                'message' => "Cannot delete role. It is currently assigned to {$memberCount} member(s)"
            ], 409);
        }

        $role->delete();

        return response()->json([
            'status' => 200,
            'message' => 'Role deleted successfully'
        ]);
    }

    /**
     * Get all permissions
     */
    public function permissions()
    {
        $permissions = Permission::orderBy('name')->get();

        return response()->json([
            'status' => 200,
            'permissions' => $permissions
        ]);
    }

    /**
     * Assign role to member
     */
    public function assignToMember(Request $request, Role $role)
    {
        $validated = $request->validate([
            'member_id' => 'required|exists:members,id',
            'congregation' => 'nullable|string|max:100',
            'parish' => 'nullable|string|max:100',
            'presbytery' => 'nullable|string|max:100',
            'expires_at' => 'nullable|date|after:now'
        ]);

        $member = Member::findOrFail($validated['member_id']);

        $success = $member->assignRole(
            $role,
            $validated['congregation'] ?? null,
            $validated['parish'] ?? null,
            $validated['presbytery'] ?? null,
            $validated['expires_at'] ?? null
        );

        if ($success) {
            return response()->json([
                'status' => 200,
                'message' => "Role '{$role->name}' assigned to member successfully"
            ]);
        }

        return response()->json([
            'status' => 500,
            'message' => 'Failed to assign role to member'
        ], 500);
    }

    /**
     * Remove role from member
     */
    public function removeFromMember(Request $request, Role $role)
    {
        $validated = $request->validate([
            'member_id' => 'required|exists:members,id',
            'congregation' => 'nullable|string|max:100',
            'parish' => 'nullable|string|max:100',
            'presbytery' => 'nullable|string|max:100'
        ]);

        $member = Member::findOrFail($validated['member_id']);

        $success = $member->removeRole(
            $role,
            $validated['congregation'] ?? null,
            $validated['parish'] ?? null,
            $validated['presbytery'] ?? null
        );

        if ($success) {
            return response()->json([
                'status' => 200,
                'message' => "Role '{$role->name}' removed from member successfully"
            ]);
        }

        return response()->json([
            'status' => 500,
            'message' => 'Failed to remove role from member'
        ], 500);
    }

    /**
     * Get members with specific role
     */
    public function members(Role $role, Request $request)
    {
        $query = $role->members()
                     ->wherePivot('is_active', true)
                     ->withPivot(['congregation', 'parish', 'presbytery', 'assigned_at', 'expires_at']);

        // Filter by congregation
        if ($request->has('congregation')) {
            $query->wherePivot('congregation', $request->congregation);
        }

        // Filter by parish
        if ($request->has('parish')) {
            $query->wherePivot('parish', $request->parish);
        }

        // Filter by presbytery
        if ($request->has('presbytery')) {
            $query->wherePivot('presbytery', $request->presbytery);
        }

        $members = $query->paginate(20);

        return response()->json([
            'status' => 200,
            'members' => $members
        ]);
    }
}

