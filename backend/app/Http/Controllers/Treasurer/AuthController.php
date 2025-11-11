<?php

namespace App\Http\Controllers\Treasurer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    /**
     * Get the authenticated treasurer's information
     */
    public function me(Request $request)
    {
        $user = $request->user();
        
        if (!$user->hasRole('treasurer')) {
            return response()->json(['message' => 'Access denied. Treasurer role required.'], 403);
        }

        return response()->json([
            'status' => 200,
            'user' => $user,
            'roles' => $user->activeRoles()->get(),
            'permissions' => $user->activeRoles()->with('permissions')->get()->pluck('permissions')->flatten()->unique('id'),
        ]);
    }

    /**
     * Logout the authenticated treasurer
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

