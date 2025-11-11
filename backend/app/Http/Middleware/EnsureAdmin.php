<?php

namespace App\Http\Middleware;

use App\Models\Admin;
use Closure;
use Illuminate\Http\Request;

class EnsureAdmin
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        if (!$user instanceof Admin) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }
        return $next($request);
    }
}



