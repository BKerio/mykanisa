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
        $requiredRoles = $this->normalizeRoles($role);

        // Check if user is a Member
        if ($user instanceof Member) {
            // Elder has full permissions - bypass scope checks
            // Check role from members.role field (not member_roles table)
            $memberRole = strtolower(trim($user->role ?? 'member'));
            if ($memberRole === 'elder') {
                $hasRole = true;
            } else {
                $hasRole = in_array($memberRole, $requiredRoles, true);
            }
        }
        // Check if user is an Admin
        elseif ($user instanceof Admin) {
            foreach ($requiredRoles as $requiredRole) {
                if ($user->hasRole($requiredRole)) {
                    $hasRole = true;
                    break;
                }
            }
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
                    $hasRole = in_array($memberRole, $requiredRoles, true);
                }
            }
        }

        if (!$hasRole) {
            return response()->json([
                'message' => 'Insufficient permissions. Required role: ' . implode('|', $requiredRoles)
            ], 403);
        }

        return $next($request);
    }

    /**
     * Normalize the role string into an array of lowercase role slugs.
     */
    protected function normalizeRoles(string $role): array
    {
        $segments = preg_split('/[|,]/', $role) ?: [$role];

        $roles = array_filter(array_map(function ($segment) {
            return strtolower(trim($segment));
        }, $segments));

        // If parsing resulted in an empty array, fall back to the original string
        if (empty($roles)) {
            $roles[] = strtolower(trim($role));
        }

        return array_values(array_unique($roles));
    }
}

