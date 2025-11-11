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

        return response()->json([
            'status' => 200,
            'user' => $user,
            'roles' => $user->activeRoles()->get(),
            'permissions' => $user->activeRoles()->with('permissions')->get()->pluck('permissions')->flatten()->unique('id'),
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

