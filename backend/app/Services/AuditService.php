<?php

namespace App\Services;

use App\Models\AuditLog;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Request;

class AuditService
{
    /**
     * Log an activity.
     *
     * @param string $action Short action code (e.g., 'Update', 'Login')
     * @param string $description Human readable description
     * @param mixed $model The related model (optional)
     * @param array $details Extra details (optional)
     * @return void
     */
    public static function log($action, $description, $model = null, $details = null)
    {
        try {
            $user = Auth::user(); // Might be Sanctum auth
            
            AuditLog::create([
                'user_id' => $user ? $user->id : null,
                'action' => $action,
                'description' => substr($description, 0, 65000), // Safety clip
                'model_type' => $model ? get_class($model) : null,
                'model_id' => $model ? $model->id : null,
                'details' => $details, 
                'ip_address' => Request::ip(),
                'user_agent' => substr(Request::userAgent() ?? '', 0, 255),
            ]);
        } catch (\Exception $e) {
            \Log::error('Failed to create audit log: ' . $e->getMessage());
        }
    }
}
