<?php

namespace App\Http\Middleware;

use App\Models\Admin;
use App\Models\Member;
use Closure;
use Illuminate\Http\Request;

class EnsurePermission
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @param  string  ...$permissions
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
    public function handle(Request $request, Closure $next, ...$permissions)
    {
        $user = $request->user();
        
        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        // Check if user has any of the required permissions
        if ($user instanceof Admin || $user instanceof Member) {
            // Elder has full permissions - bypass check
            if ($user instanceof Member && $user->hasRole('elder')) {
                return $next($request);
            }
            if (empty($permissions) || $user->hasAnyPermission($permissions)) {
                return $next($request);
            }
        }

        return response()->json([
            'message' => 'Insufficient permissions. Required permissions: ' . implode(', ', $permissions)
        ], 403);
    }
}

