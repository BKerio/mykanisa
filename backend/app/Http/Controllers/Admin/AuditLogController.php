<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use Illuminate\Http\Request;

use Illuminate\Database\Eloquent\Relations\MorphTo;

class AuditLogController extends Controller
{
    public function index(Request $request)
    {
        // Eager load member only if user is a User model
        $query = AuditLog::with(['user' => function (MorphTo $morphTo) {
            $morphTo->morphWith([
                \App\Models\User::class => ['member'],
            ]);
        }])->orderBy('created_at', 'desc');

        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('description', 'like', "%{$search}%")
                  ->orWhere('action', 'like', "%{$search}%")
                  ->orWhereHasMorph('user', ['App\Models\User', 'App\Models\Admin'], function ($uq) use ($search) {
                      $uq->where('name', 'like', "%{$search}%")
                         ->orWhere('email', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->has('action')) {
            $query->where('action', $request->action);
        }

        $logs = $query->paginate(20);

        return response()->json([
            'status' => 200,
            'data' => $logs,
        ]);
    }
}
