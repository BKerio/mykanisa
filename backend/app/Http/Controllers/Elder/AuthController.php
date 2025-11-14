<?php

namespace App\Http\Controllers\Elder;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AuthController extends Controller
{
    /**
     * Get the authenticated elder's information
     */
    public function me(Request $request)
    {
        $user = $request->user();
        
        // Ensure user has elder role
        if (!$user->hasRole('elder')) {
            return response()->json(['message' => 'Access denied. Elder role required.'], 403);
        }

        // Get role from members.role field (not member_roles table)
        $memberRole = $user->role ?? 'member';
        
        // Get permissions for the role from roles table
        $role = \App\Models\Role::where('slug', $memberRole)->first();
        $permissions = $role ? $role->permissions()->get() : collect();
        
        return response()->json([
            'status' => 200,
            'user' => $user,
            'roles' => [['slug' => $memberRole, 'name' => ucfirst($memberRole)]],
            'permissions' => $permissions,
        ]);
    }

    /**
     * Logout the authenticated elder
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        
        return response()->json([
            'status' => 200,
            'message' => 'Successfully logged out'
        ]);
    }
}

