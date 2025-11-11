<?php

namespace App\Http\Middleware;

use App\Models\Admin;
use App\Models\Member;
use Closure;
use Illuminate\Http\Request;

class EnsureLeadership
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        
        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        // Admins are always considered leaders
        if ($user instanceof Admin) {
            return $next($request);
        }
        
        // Check if member is a leader
        if ($user instanceof Member) {
            // Get scope from request parameters
            $congregation = $request->input('congregation');
            $parish = $request->input('parish');
            $presbytery = $request->input('presbytery');
            
            if ($user->isLeader($congregation, $parish, $presbytery)) {
                return $next($request);
            }
        }

        return response()->json([
            'message' => 'Access denied. Leadership role required.'
        ], 403);
    }
}

