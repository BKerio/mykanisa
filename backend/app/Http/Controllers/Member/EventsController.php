<?php

namespace App\Http\Controllers\Member;

use App\Http\Controllers\Controller;
use App\Models\CongregationEvent;
use App\Models\Member;
use Illuminate\Http\Request;

class EventsController extends Controller
{
    /**
     * Get all events for the member's congregation
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        // Get member ID and congregation
        $memberId = null;
        $congregation = null;
        if ($user instanceof Member) {
            $memberId = $user->id;
            $congregation = $user->congregation;
        } else {
            $member = Member::where('email', $user->email)->first();
            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member record not found'
                ], 404);
            }
            $memberId = $member->id;
            $congregation = $member->congregation;
        }

        if (empty($congregation)) {
            return response()->json([
                'status' => 200,
                'events' => []
            ]);
        }

        // Get all events for this congregation created by any elder
        // This includes all events regardless of which elder created them
        $events = CongregationEvent::where('congregation', $congregation)
            ->orderBy('event_date', 'asc')
            ->orderBy('start_time', 'asc')
            ->with(['creator:id,full_name'])
            ->get();

        // Log for debugging
        \Log::info('Member events request', [
            'member_id' => $memberId,
            'congregation' => $congregation,
            'events_count' => $events->count()
        ]);

        return response()->json([
            'status' => 200,
            'events' => $events,
            'total' => $events->count(),
            'congregation' => $congregation
        ]);
    }

    /**
     * Get a specific event
     */
    public function show(Request $request, $id)
    {
        $user = $request->user();
        
        // Get member ID and congregation
        $memberId = null;
        $congregation = null;
        if ($user instanceof Member) {
            $memberId = $user->id;
            $congregation = $user->congregation;
        } else {
            $member = Member::where('email', $user->email)->first();
            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member record not found'
                ], 404);
            }
            $memberId = $member->id;
            $congregation = $member->congregation;
        }

        $event = CongregationEvent::where('id', $id)
            ->where('congregation', $congregation)
            ->with(['creator:id,full_name'])
            ->first();

        if (!$event) {
            return response()->json([
                'status' => 404,
                'message' => 'Event not found'
            ], 404);
        }

        return response()->json([
            'status' => 200,
            'event' => $event
        ]);
    }
}

