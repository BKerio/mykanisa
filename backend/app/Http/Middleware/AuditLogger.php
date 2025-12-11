<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Services\AuditService;
use Symfony\Component\HttpFoundation\Response;

class AuditLogger
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        // Terminate / After response logic is handled by just running code after $next
        // But for reliable User Auth, we usually need the request to be handled.
        // We only log modification methods to reduce noise
        if (in_array($request->method(), ['POST', 'PUT', 'PATCH', 'DELETE'])) {
            try {
                $user = $request->user();
                $method = $request->method();
                $path = $request->path();
                
                // Filter sensitive data
                $input = $request->all();
                $hiddenKeys = ['password', 'password_confirmation', 'token', 'secret'];
                array_walk_recursive($input, function(&$v, $k) use ($hiddenKeys) {
                    if (in_array(strtolower($k), $hiddenKeys)) {
                        $v = '********';
                    }
                });

                $description = ($user ? $user->name : 'System/Guest') . " performed $method on " . $path;
                
                AuditService::log($method, $description, null, $input);
            } catch (\Exception $e) {
                // Do not fail request if logging fails
                \Log::error('AuditLogger Middleware Error: ' . $e->getMessage());
            }
        }

        return $response;
    }
}
