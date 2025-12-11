<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Services\AuditService;
use Symfony\Component\HttpFoundation\Response;

use Laravel\Sanctum\PersonalAccessToken;

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

        // Terminate / After response logic
        if (in_array($request->method(), ['POST', 'PUT', 'PATCH', 'DELETE'])) {
            try {
                $user = $request->user();
                
                // If user is not resolved via Auth middleware yet (since this runs globally),
                // try to resolve via Sanctum token manually
                if (!$user && $request->bearerToken()) {
                    $token = PersonalAccessToken::findToken($request->bearerToken());
                    if ($token) {
                        $user = $token->tokenable;
                    }
                }

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

                $description = $this->enrichDescription($method, $path, $input, $user);
                
                AuditService::log($method, $description, null, $input, $user);
            } catch (\Exception $e) {
                // Do not fail request if logging fails
                \Log::error('AuditLogger Middleware Error: ' . $e->getMessage());
            }
        }

        return $response;
    }

    private function enrichDescription($method, $path, $input, $user)
    {
        $userName = 'Guest/System';
        
        if ($user) {
            // Try to get E-Kanisa Number via Member relationship
            // Check if user has loaded 'member' or can load it
            $member = $user->member; 
            if (!$member && method_exists($user, 'member')) {
                // Attempt to load if not loaded, though validation usually ensures member context
                $member = $user->member()->first();
            }
            
            if ($member && !empty($member->e_kanisa_number)) {
                $userName = "Member #{$member->e_kanisa_number} ({$user->name})";
            } elseif ($user instanceof \App\Models\Admin) {
                $userName = "Admin {$user->name}";
            } else {
                $userName = $user->name ?? $user->email ?? 'Unknown User';
            }
        }
        
        $act = "performed $method on";
        $target = $path;
        
        // Humanize common paths
        if (str_contains($path, 'login')) {
            $identifier = $input['email'] ?? $input['identifier'] ?? 'Unknown';
            return "Login attempt by $identifier";
        }
        if (str_contains($path, 'forgot-password')) {
            $identifier = $input['identifier'] ?? 'Unknown';
            return "Password reset request for $identifier";
        }
        
        // Humanize common paths
        if (str_contains($path, 'minutes/tasks')) {
            if (str_contains($path, 'status')) return "$userName updated a Task Status";
            return "$userName managed a Task";
        }
        if (str_contains($path, 'minutes')) {
            if ($method === 'POST') return "$userName created new Meeting Minutes";
            if (in_array($method, ['PUT', 'PATCH'])) return "$userName updated Meeting Minutes";
        }
        if (str_contains($path, 'contributions')) {
            if ($method === 'POST') return "$userName recorded a Contribution";
            if (in_array($method, ['PUT', 'PATCH'])) return "$userName updated a Contribution";
        }
        if (str_contains($path, 'members')) {
            if (str_contains($path, 'dependents')) return "$userName managed Dependents";
            if ($method === 'POST') return "$userName registered a new Member";
            if (in_array($method, ['PUT', 'PATCH'])) return "$userName updated Member details";
        }

        return "$userName $act $target";
    }
}
