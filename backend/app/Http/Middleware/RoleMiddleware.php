<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Member;
use App\Models\Admin;

class RoleMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @param  string  $role
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
    public function handle(Request $request, Closure $next, string $role)
    {
        if (!Auth::check()) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $user = Auth::user();
        $hasRole = false;

        // Check if user is a Member
        if ($user instanceof Member) {
            // Elder has full permissions - bypass scope checks
            // Check role from members.role field (not member_roles table)
            $memberRole = strtolower(trim($user->role ?? 'member'));
            if ($memberRole === 'elder') {
                $hasRole = true;
            } else {
                // Check if member has the required role from members.role field
                $requiredRole = strtolower(trim($role));
                $hasRole = $memberRole === $requiredRole;
            }
        }
        // Check if user is an Admin
        elseif ($user instanceof Admin) {
            $hasRole = $user->hasRole($role);
        }
        // If user is a regular User, try to find associated Member
        else {
            $member = Member::where('email', $user->email)->first();
            if ($member) {
                // Elder has full permissions - bypass scope checks
                // Check role from members.role field (not member_roles table)
                $memberRole = strtolower(trim($member->role ?? 'member'));
                if ($memberRole === 'elder') {
                    $hasRole = true;
                } else {
                    // Check if member has the required role from members.role field
                    $requiredRole = strtolower(trim($role));
                    $hasRole = $memberRole === $requiredRole;
                }
            }
        }

        if (!$hasRole) {
            return response()->json([
                'message' => 'Insufficient permissions. Required role: ' . $role
            ], 403);
        }

        return $next($request);
    }
}

