<?php

namespace App\Http\Controllers\YouthLeader;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    /**
     * Get the authenticated youth leader's information
     */
    public function me(Request $request)
    {
        $user = $request->user();
        $member = \App\Models\Member::where('email', $user->email)->first();
        
        if (!$member || $member->role !== 'youth_leader') {
            return response()->json(['message' => 'Access denied. Youth Leader role required.'], 403);
        }

        // Load assigned group if exists
        $assignedGroup = null;
        if ($member->assigned_group_id) {
            $assignedGroup = $member->assignedGroup()->first(['id', 'name', 'description']);
        }

        return response()->json([
            'status' => 200,
            'user' => $user,
            'member' => $member->only(['id', 'full_name', 'email', 'assigned_group_id']),
            'assigned_group' => $assignedGroup,
            'roles' => $user->activeRoles()->get(),
            'permissions' => $user->activeRoles()->with('permissions')->get()->pluck('permissions')->flatten()->unique('id'),
        ]);
    }

    /**
     * Logout the authenticated youth leader
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

