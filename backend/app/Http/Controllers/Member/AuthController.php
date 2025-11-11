<?php

namespace App\Http\Controllers\Member;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    /**
     * Get the authenticated member's information
     */
    public function me(Request $request)
    {
        $user = $request->user();
        
        // Members can access their own profile
        return response()->json([
            'status' => 200,
            'user' => $user,
            'roles' => $user->activeRoles()->get(),
            'permissions' => $user->activeRoles()->with('permissions')->get()->pluck('permissions')->flatten()->unique('id'),
        ]);
    }

    /**
     * Logout the authenticated member
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

