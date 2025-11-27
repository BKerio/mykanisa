<?php

namespace App\Http\Controllers\Elder;

use App\Http\Controllers\Controller;
use App\Models\CongregationEvent;
use App\Models\Member;
use App\Services\SmsService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class EventsController extends Controller
{
    protected SmsService $smsService;

    public function __construct(SmsService $smsService)
    {
        $this->smsService = $smsService;
    }

    /**
     * Get all events created by this elder
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        // Get member ID
        $memberId = null;
        if ($user instanceof Member) {
            $memberId = $user->id;
        } else {
            $member = Member::where('email', $user->email)->first();
            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member record not found'
                ], 404);
            }
            $memberId = $member->id;
        }

        $events = CongregationEvent::where('created_by', $memberId)
            ->orderBy('event_date', 'desc')
            ->orderBy('start_time', 'desc')
            ->get();

        return response()->json([
            'status' => 200,
            'events' => $events
        ]);
    }

    /**
     * Create a new event and send SMS notifications to all members in the congregation
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'location' => 'nullable|string|max:255',
            'event_date' => 'nullable|date',
            'start_time' => 'nullable|date_format:H:i',
            'end_time' => 'nullable|date_format:H:i',
            'is_all_day' => 'sometimes|boolean',
            // Flutter app format
            'start_at' => 'nullable|date',
            'end_at' => 'nullable|date|after:start_at',
            'all_day' => 'sometimes|boolean',
        ]);

        $user = $request->user();
        
        // Get member ID
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
                    'message' => 'Member record not found for authenticated user'
                ], 404);
            }
            $memberId = $member->id;
            $congregation = $member->congregation;
        }

        if (empty($congregation)) {
            return response()->json([
                'status' => 400,
                'message' => 'Congregation not found. Please ensure your profile has a congregation assigned.'
            ], 400);
        }

        // Handle both Flutter format (start_at/end_at) and direct format (event_date/start_time)
        $eventDate = null;
        $startTime = null;
        $endTime = null;
        $isAllDay = $validated['is_all_day'] ?? $validated['all_day'] ?? false;

        if (isset($validated['start_at'])) {
            // Flutter format: start_at is a full datetime
            $startAt = \Carbon\Carbon::parse($validated['start_at']);
            $eventDate = $startAt->format('Y-m-d');
            if (!$isAllDay) {
                $startTime = $startAt->format('H:i');
            }
            
            if (isset($validated['end_at'])) {
                $endAt = \Carbon\Carbon::parse($validated['end_at']);
                if (!$isAllDay) {
                    $endTime = $endAt->format('H:i');
                }
            }
        } else {
            // Direct format
            $eventDate = $validated['event_date'];
            $startTime = $validated['start_time'] ?? null;
            $endTime = $validated['end_time'] ?? null;
        }

        // Create the event
        $event = CongregationEvent::create([
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'location' => $validated['location'] ?? null,
            'event_date' => $eventDate,
            'start_time' => $startTime,
            'end_time' => $endTime,
            'is_all_day' => $isAllDay,
            'congregation' => $congregation,
            'created_by' => $memberId,
        ]);

        // Send SMS notifications to all members in the congregation
        $smsSentCount = 0;
        $smsFailedCount = 0;
        
        $members = Member::where('congregation', $congregation)
            ->where('is_active', true)
            ->whereNotNull('telephone')
            ->where('telephone', '!=', '')
            ->get();

        $sender = Member::find($memberId);
        $senderName = $sender ? $sender->full_name : 'Church Elder';

        // Format event date and time for SMS
        $eventDate = $event->event_date->format('l, F j, Y');
        $timeInfo = '';
        if ($event->is_all_day) {
            $timeInfo = 'All Day';
        } elseif ($event->start_time && $event->end_time) {
            // Handle both 'H:i' and 'H:i:s' formats
            $startTimeStr = is_string($event->start_time) ? $event->start_time : $event->start_time->format('H:i:s');
            $endTimeStr = is_string($event->end_time) ? $event->end_time : $event->end_time->format('H:i:s');
            $startTime = \Carbon\Carbon::parse($startTimeStr)->format('g:i A');
            $endTime = \Carbon\Carbon::parse($endTimeStr)->format('g:i A');
            $timeInfo = $startTime . ' - ' . $endTime;
        } elseif ($event->start_time) {
            $startTimeStr = is_string($event->start_time) ? $event->start_time : $event->start_time->format('H:i:s');
            $startTime = \Carbon\Carbon::parse($startTimeStr)->format('g:i A');
            $timeInfo = 'Starting at ' . $startTime;
        }

        foreach ($members as $member) {
            $smsMessage = "NEW CHURCH EVENT\n\n";
            $smsMessage .= "Hello {$member->full_name},\n\n";
            $smsMessage .= "{$senderName} has created a new event:\n\n";
            $smsMessage .= "📅 {$event->title}\n\n";
            
            if (!empty($event->description)) {
                $smsMessage .= "{$event->description}\n\n";
            }
            
            $smsMessage .= "Date: {$eventDate}\n";
            
            if (!empty($timeInfo)) {
                $smsMessage .= "Time: {$timeInfo}\n";
            }
            
            if (!empty($event->location)) {
                $smsMessage .= "Location: {$event->location}\n";
            }
            
            $smsMessage .= "\nWe hope to see you there!\n\n";
            $smsMessage .= "- PCEA Church";

            try {
                $smsResult = $this->smsService->sendSms($member->telephone, $smsMessage);
                if ($smsResult) {
                    $smsSentCount++;
                } else {
                    $smsFailedCount++;
                    Log::warning('Failed to send event SMS', [
                        'event_id' => $event->id,
                        'member_id' => $member->id,
                        'phone' => $member->telephone,
                    ]);
                }
            } catch (\Exception $e) {
                $smsFailedCount++;
                Log::error('Error sending event SMS', [
                    'event_id' => $event->id,
                    'member_id' => $member->id,
                    'phone' => $member->telephone,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        // Update event with SMS count
        $event->update(['sms_sent_count' => $smsSentCount]);

        Log::info('Event created and SMS notifications sent', [
            'event_id' => $event->id,
            'congregation' => $congregation,
            'total_members' => $members->count(),
            'sms_sent' => $smsSentCount,
            'sms_failed' => $smsFailedCount,
        ]);

        return response()->json([
            'status' => 201,
            'message' => $smsSentCount > 0
                ? "Event created and sent to {$smsSentCount} member(s)." . 
                  ($smsFailedCount > 0 ? " Failed to send to {$smsFailedCount} member(s)." : "")
                : ($smsFailedCount > 0 
                    ? "Event created but failed to send SMS to {$smsFailedCount} member(s)." 
                    : 'Event created successfully.'),
            'event' => $event,
            'sms_sent_count' => $smsSentCount,
            'sms_failed_count' => $smsFailedCount,
        ], 201);
    }

    /**
     * Get a specific event
     */
    public function show(Request $request, $id)
    {
        $user = $request->user();
        
        // Get member ID
        $memberId = null;
        if ($user instanceof Member) {
            $memberId = $user->id;
        } else {
            $member = Member::where('email', $user->email)->first();
            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member record not found'
                ], 404);
            }
            $memberId = $member->id;
        }

        $event = CongregationEvent::where('id', $id)
            ->where('created_by', $memberId)
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

    /**
     * Update an event
     */
    public function update(Request $request, $id)
    {
        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'location' => 'nullable|string|max:255',
            'event_date' => 'nullable|date',
            'start_time' => 'nullable|date_format:H:i',
            'end_time' => 'nullable|date_format:H:i',
            'is_all_day' => 'sometimes|boolean',
            // Flutter app format
            'start_at' => 'nullable|date',
            'end_at' => 'nullable|date|after:start_at',
            'all_day' => 'sometimes|boolean',
        ]);

        $user = $request->user();
        
        // Get member ID
        $memberId = null;
        if ($user instanceof Member) {
            $memberId = $user->id;
        } else {
            $member = Member::where('email', $user->email)->first();
            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member record not found'
                ], 404);
            }
            $memberId = $member->id;
        }

        $event = CongregationEvent::where('id', $id)
            ->where('created_by', $memberId)
            ->first();

        if (!$event) {
            return response()->json([
                'status' => 404,
                'message' => 'Event not found'
            ], 404);
        }

        // Handle both Flutter format (start_at/end_at) and direct format (event_date/start_time)
        $updateData = [];
        
        if (isset($validated['title'])) {
            $updateData['title'] = $validated['title'];
        }
        if (isset($validated['description'])) {
            $updateData['description'] = $validated['description'];
        }
        if (isset($validated['location'])) {
            $updateData['location'] = $validated['location'];
        }

        $eventDate = null;
        $startTime = null;
        $endTime = null;
        $isAllDay = $validated['is_all_day'] ?? $validated['all_day'] ?? $event->is_all_day;

        if (isset($validated['start_at'])) {
            // Flutter format: start_at is a full datetime
            $startAt = \Carbon\Carbon::parse($validated['start_at']);
            $eventDate = $startAt->format('Y-m-d');
            if (!$isAllDay) {
                $startTime = $startAt->format('H:i');
            }
            
            if (isset($validated['end_at'])) {
                $endAt = \Carbon\Carbon::parse($validated['end_at']);
                if (!$isAllDay) {
                    $endTime = $endAt->format('H:i');
                }
            }
        } else {
            // Direct format
            if (isset($validated['event_date'])) {
                $eventDate = $validated['event_date'];
            }
            if (isset($validated['start_time'])) {
                $startTime = $validated['start_time'];
            }
            if (isset($validated['end_time'])) {
                $endTime = $validated['end_time'];
            }
        }

        if ($eventDate !== null) {
            $updateData['event_date'] = $eventDate;
        }
        if ($startTime !== null) {
            $updateData['start_time'] = $startTime;
        }
        if ($endTime !== null) {
            $updateData['end_time'] = $endTime;
        } elseif (isset($validated['end_at']) && $validated['end_at'] === null) {
            // Explicitly set to null if end_at is null
            $updateData['end_time'] = null;
        }
        
        $updateData['is_all_day'] = $isAllDay;

        $event->update($updateData);

        return response()->json([
            'status' => 200,
            'message' => 'Event updated successfully',
            'event' => $event->fresh()
        ]);
    }

    /**
     * Delete an event
     */
    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        
        // Get member ID
        $memberId = null;
        if ($user instanceof Member) {
            $memberId = $user->id;
        } else {
            $member = Member::where('email', $user->email)->first();
            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member record not found'
                ], 404);
            }
            $memberId = $member->id;
        }

        $event = CongregationEvent::where('id', $id)
            ->where('created_by', $memberId)
            ->first();

        if (!$event) {
            return response()->json([
                'status' => 404,
                'message' => 'Event not found'
            ], 404);
        }

        $event->delete();

        return response()->json([
            'status' => 200,
            'message' => 'Event deleted successfully'
        ]);
    }
}

