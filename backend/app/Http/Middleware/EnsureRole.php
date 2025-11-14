<?php

namespace App\Http\Middleware;

use App\Models\Admin;
use App\Models\Member;
use Closure;
use Illuminate\Http\Request;

class EnsureRole
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @param  string  ...$roles
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
    public function handle(Request $request, Closure $next, ...$roles)
    {
        $user = $request->user();
        
        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        // Check if user is admin
        if ($user instanceof Admin) {
            // Admins can have roles too
            if (empty($roles) || $user->hasAnyRole($roles)) {
                return $next($request);
            }
        }
        
        // Check if user is member
        if ($user instanceof Member) {
            // Elder has full permissions - bypass scope checks
            // Check role from members.role field (not member_roles table)
            $memberRole = strtolower(trim($user->role ?? 'member'));
            if ($memberRole === 'elder') {
                return $next($request);
            }
            
            // Check if member has any of the required roles from members.role field
            if (empty($roles) || $user->hasAnyRole($roles)) {
                return $next($request);
            }
        }

        return response()->json([
            'message' => 'Insufficient permissions. Required roles: ' . implode(', ', $roles)
        ], 403);
    }
}

