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

    public function communications(Request $request)
    {
        // Fetch global communications (Announcements)
        $query = \App\Models\Announcement::with(['sender', 'group']) // Add recipient/group relationships as needed
            ->orderBy('created_at', 'desc');

        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->where('title', 'like', "%{$search}%")
                  ->orWhere('message', 'like', "%{$search}%");
        }

        $data = $query->paginate(20);
        return response()->json(['status' => 200, 'data' => $data]);
    }

    public function tasks(Request $request)
    {
        // Fetch global tasks (MinuteActionItems)
        // Assuming MinuteActionItem exists and has 'assigned_to' or similar
        // Need to check relationship. Assuming 'assignedHandlers' or 'members'
        $query = \App\Models\MinuteActionItem::with(['minute']) // Eager load minute for context
            ->orderBy('created_at', 'desc');

        if ($request->has('search') && !empty($request->search)) {
             $search = $request->search;
             $query->where('action', 'like', "%{$search}%");
        }

        $data = $query->paginate(20);
        return response()->json(['status' => 200, 'data' => $data]);
    }

    public function attendances(Request $request)
    {
        // Fetch global attendances
        $query = \App\Models\Attendance::with(['member'])
            ->orderBy('event_date', 'desc')
            ->orderBy('created_at', 'desc');

        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->whereHas('member', function($q) use ($search){
                $q->where('full_name', 'like', "%{$search}%")
                  ->orWhere('e_kanisa_number', 'like', "%{$search}%");
            });
        }

        $data = $query->paginate(20);
        return response()->json(['status' => 200, 'data' => $data]);
    }
}
