<?php

namespace App\Http\Controllers\Secretary;

use App\Http\Controllers\Controller;
use App\Models\Member;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CommunicationsController extends Controller
{
    /**
     * Send notification to members
     */
    public function sendNotification(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'target_type' => 'required|in:all,congregation,parish,presbytery,members',
            'target_value' => 'nullable|string',
            'send_method' => 'required|in:sms,email,both',
        ]);

        $user = $request->user();
        
        // Get target members based on scope
        $query = Member::query();
        
        $congregation = $request->input('congregation');
        $parish = $request->input('parish');
        $presbytery = $request->input('presbytery');
        
        if ($congregation) {
            $query->where('congregation', $congregation);
        }
        if ($parish) {
            $query->where('parish', $parish);
        }
        if ($presbytery) {
            $query->where('presbytery', $presbytery);
        }
        
        // Apply target filters
        switch ($validated['target_type']) {
            case 'congregation':
                if ($validated['target_value']) {
                    $query->where('congregation', $validated['target_value']);
                }
                break;
            case 'parish':
                if ($validated['target_value']) {
                    $query->where('parish', $validated['target_value']);
                }
                break;
            case 'presbytery':
                if ($validated['target_value']) {
                    $query->where('presbytery', $validated['target_value']);
                }
                break;
            case 'members':
                if ($validated['target_value']) {
                    $memberIds = explode(',', $validated['target_value']);
                    $query->whereIn('id', $memberIds);
                }
                break;
        }
        
        $members = $query->where('is_active', true)->get();
        
        // Log the notification
        DB::table('notifications')->insert([
            'title' => $validated['title'],
            'message' => $validated['message'],
            'sent_by' => $user->id,
            'target_count' => $members->count(),
            'send_method' => $validated['send_method'],
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        
        return response()->json([
            'status' => 200,
            'message' => 'Notification sent successfully',
            'target_count' => $members->count(),
            'members' => $members->pluck('full_name')
        ]);
    }

    /**
     * Get communication history
     */
    public function history(Request $request)
    {
        $user = $request->user();
        
        $notifications = DB::table('notifications')
            ->where('sent_by', $user->id)
            ->orderBy('created_at', 'desc')
            ->paginate(20);
            
        return response()->json([
            'status' => 200,
            'notifications' => $notifications
        ]);
    }

    /**
     * Get member contact information for communications
     */
    public function memberContacts(Request $request)
    {
        $user = $request->user();
        
        $query = Member::query();
        
        $congregation = $request->input('congregation');
        
        if ($congregation) {
            $query->where('congregation', $congregation);
        }
        
        $members = $query->select('id', 'full_name', 'email', 'telephone', 'congregation')
            ->where('is_active', true)
            ->orderBy('full_name')
            ->get();
            
        return response()->json([
            'status' => 200,
            'members' => $members
        ]);
    }
}

