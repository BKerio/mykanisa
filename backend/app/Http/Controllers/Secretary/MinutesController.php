<?php

namespace App\Http\Controllers\Secretary;

use App\Http\Controllers\Controller;
use App\Models\Minute;
use App\Models\MinuteAttendee;
use App\Models\MinuteAgendaItem;
use App\Models\MinuteActionItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;

class MinutesController extends Controller
{
    /**
     * Display a listing of minutes
     */
    public function index(Request $request)
    {
        $perPage = $request->get('per_page', 15);
        
        $minutes = Minute::with(['creator', 'attendees.member', 'agendaItems', 'actionItems'])
            ->orderBy('meeting_date', 'desc')
            ->orderBy('meeting_time', 'desc')
            ->paginate($perPage);

        return response()->json([
            'status' => 200,
            'message' => 'Minutes retrieved successfully',
            'data' => $minutes,
        ]);
    }

    /**
     * Store a newly created minute
     */
    public function store(Request $request)
    {
        // Decode JSON strings from multipart form data
        if ($request->has('attendees') && is_string($request->input('attendees'))) {
            $request->merge(['attendees' => json_decode($request->input('attendees'), true)]);
        }
        if ($request->has('agenda_items') && is_string($request->input('agenda_items'))) {
            $request->merge(['agenda_items' => json_decode($request->input('agenda_items'), true)]);
        }
        if ($request->has('action_items') && is_string($request->input('action_items'))) {
            $request->merge(['action_items' => json_decode($request->input('action_items'), true)]);
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'meeting_date' => 'required|date',
            'meeting_time' => 'required',
            'meeting_type' => 'required|in:Virtual,Physical,Hybrid',
            'location' => 'nullable|string|max:255',
            'is_online' => 'nullable|boolean',
            'online_link' => 'nullable|string|max:500',
            'notes' => 'nullable|string',
            'summary' => 'nullable|string',
            'attendees' => 'nullable|array',
            'attendees.*.member_id' => 'required|exists:members,id',
            'attendees.*.status' => 'required|in:present,absent_with_apology,absent_without_apology',
            'agenda_items' => 'nullable|array',
            'agenda_items.*.title' => 'required|string',
            'agenda_items.*.notes' => 'nullable|string',
            'agenda_items.*.order' => 'nullable|integer',
            'agenda_items.*.attachments' => 'nullable|array',
            'action_items' => 'nullable|array',
            'action_items.*.description' => 'required|string',
            'action_items.*.responsible_member_id' => 'nullable|exists:members,id',
            'action_items.*.due_date' => 'nullable|date',
            'action_items.*.status' => 'nullable|in:Pending,In progress,Done',
            'action_items.*.status_reason' => 'nullable|string',
        ]);

        try {
            DB::beginTransaction();

            // Create the minute
            $minute = Minute::create([
                'title' => $validated['title'],
                'meeting_date' => $validated['meeting_date'],
                'meeting_time' => $validated['meeting_time'],
                'meeting_type' => $validated['meeting_type'],
                'location' => $validated['location'] ?? null,
                'is_online' => $validated['is_online'] ?? false,
                'online_link' => $validated['online_link'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'summary' => $validated['summary'] ?? null,
                'created_by' => Auth::id(),
            ]);

            // Add attendees
            if (!empty($validated['attendees'])) {
                foreach ($validated['attendees'] as $attendee) {
                    MinuteAttendee::create([
                        'minute_id' => $minute->id,
                        'member_id' => $attendee['member_id'],
                        'status' => $attendee['status'],
                    ]);
                }
            }

            // Add agenda items
            if (!empty($validated['agenda_items'])) {
                foreach ($validated['agenda_items'] as $index => $item) {
                    MinuteAgendaItem::create([
                        'minute_id' => $minute->id,
                        'title' => $item['title'],
                        'notes' => $item['notes'] ?? null,
                        'order' => $item['order'] ?? $index,
                        'attachments' => $item['attachments'] ?? null,
                    ]);
                }
            }

            // Add action items
            if (!empty($validated['action_items'])) {
                foreach ($validated['action_items'] as $item) {
                    MinuteActionItem::create([
                        'minute_id' => $minute->id,
                        'description' => $item['description'],
                        'responsible_member_id' => $item['responsible_member_id'] ?? null,
                        'due_date' => $item['due_date'] ?? null,
                        'status' => $item['status'] ?? 'Pending',
                        'status_reason' => $item['status_reason'] ?? null,
                    ]);
                }
            }

            DB::commit();

            // Load relationships for response
            $minute->load(['creator', 'attendees.member', 'agendaItems', 'actionItems.responsibleMember']);

            // Send SMS notifications
            try {
                $smsService = new \App\Services\SmsService();
                foreach ($minute->attendees as $attendee) {
                    if (in_array($attendee->status, ['present', 'absent_with_apology']) && $attendee->member && $attendee->member->telephone) {
                        $memberName = $attendee->member->full_name ?? 'Member';
                        $message = "Greetings {$memberName}, Minutes for '{$minute->title}' held on {$minute->meeting_date} are now available. Please log in to the app to view them.";
                        $smsService->sendSms($attendee->member->telephone, $message);
                    }
                }
                
                // Send SMS to responsible members for action items
                foreach ($minute->actionItems as $action) {
                     if ($action->responsibleMember && $action->responsibleMember->telephone) {
                         $memberName = $action->responsibleMember->full_name ?? 'Member';
                         $dueDate = $action->due_date ? ' Due: ' . $action->due_date : '';
                         $message = "Dear {$memberName}, you have been assigned a task: \"{$action->description}\"{$dueDate}. Please check the minutes app for details.";
                         $smsService->sendSms($action->responsibleMember->telephone, $message);
                     }
                }
            } catch (\Exception $e) {
                \Log::error('Failed to send minutes SMS: ' . $e->getMessage());
                // Don't fail the request if SMS fails
            }

            return response()->json([
                'status' => 200,
                'message' => 'Minute created successfully',
                'data' => $minute,
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            
            return response()->json([
                'status' => 500,
                'message' => 'Failed to create minute: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Display the specified minute
     */
    public function show($id)
    {
        $minute = Minute::with(['creator', 'attendees.member', 'agendaItems', 'actionItems.responsibleMember'])
            ->find($id);

        if (!$minute) {
            return response()->json([
                'status' => 404,
                'message' => 'Minute not found',
            ], 404);
        }

        return response()->json([
            'status' => 200,
            'message' => 'Minute retrieved successfully',
            'data' => $minute,
        ]);
    }

    /**
     * Update the specified minute
     */
    public function update(Request $request, $id)
    {
        $minute = Minute::find($id);

        if (!$minute) {
            return response()->json([
                'status' => 404,
                'message' => 'Minute not found',
            ], 404);
        }

        // Decode JSON strings if present (similar to store)
        if ($request->has('attendees') && is_string($request->input('attendees'))) {
            $request->merge(['attendees' => json_decode($request->input('attendees'), true)]);
        }
        if ($request->has('agenda_items') && is_string($request->input('agenda_items'))) {
            $request->merge(['agenda_items' => json_decode($request->input('agenda_items'), true)]);
        }
        if ($request->has('action_items') && is_string($request->input('action_items'))) {
            $request->merge(['action_items' => json_decode($request->input('action_items'), true)]);
        }

        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'meeting_date' => 'sometimes|required|date',
            'meeting_time' => 'sometimes|required',
            'meeting_type' => 'sometimes|required|in:Virtual,Physical,Hybrid',
            'location' => 'nullable|string|max:255',
            'is_online' => 'boolean',
            'online_link' => 'nullable|string|max:500',
            'notes' => 'nullable|string',
            'summary' => 'nullable|string',
            'attendees' => 'nullable|array',
            'attendees.*.member_id' => 'sometimes|required|exists:members,id',
            'attendees.*.status' => 'sometimes|required|in:present,absent_with_apology,absent_without_apology',
            'agenda_items' => 'nullable|array',
            'agenda_items.*.title' => 'sometimes|required|string',
            'agenda_items.*.notes' => 'nullable|string',
            'agenda_items.*.order' => 'nullable|integer',
            'agenda_items.*.attachments' => 'nullable|array',
            'action_items' => 'nullable|array',
            'action_items.*.description' => 'sometimes|required|string',
            'action_items.*.responsible_member_id' => 'nullable|exists:members,id',
            'action_items.*.due_date' => 'nullable|date',
            'action_items.*.status' => 'nullable|in:Pending,In progress,Done',
            'action_items.*.status_reason' => 'nullable|string',
        ]);

        try {
            DB::beginTransaction();

            $minute->update($validated);

            // Sync Attendees
            if ($request->has('attendees')) {
                MinuteAttendee::where('minute_id', $minute->id)->delete();
                if (!empty($validated['attendees'])) {
                    foreach ($validated['attendees'] as $attendee) {
                        MinuteAttendee::create([
                            'minute_id' => $minute->id,
                            'member_id' => $attendee['member_id'],
                            'status' => $attendee['status'],
                        ]);
                    }
                }
            }

            // Sync Agenda Items
            if ($request->has('agenda_items')) {
                MinuteAgendaItem::where('minute_id', $minute->id)->delete();
                if (!empty($validated['agenda_items'])) {
                    foreach ($validated['agenda_items'] as $index => $item) {
                        MinuteAgendaItem::create([
                            'minute_id' => $minute->id,
                            'title' => $item['title'],
                            'notes' => $item['notes'] ?? null,
                            'order' => $item['order'] ?? $index,
                            'attachments' => $item['attachments'] ?? null,
                        ]);
                    }
                }
            }

            // Sync Action Items
            if ($request->has('action_items')) {
                MinuteActionItem::where('minute_id', $minute->id)->delete();
                if (!empty($validated['action_items'])) {
                    foreach ($validated['action_items'] as $item) {
                        MinuteActionItem::create([
                            'minute_id' => $minute->id,
                            'description' => $item['description'],
                            'responsible_member_id' => $item['responsible_member_id'] ?? null,
                            'due_date' => $item['due_date'] ?? null,
                            'status' => $item['status'] ?? 'Pending',
                            'status_reason' => $item['status_reason'] ?? null,
                        ]);
                    }
                }
            }

            DB::commit();

            $minute->load(['creator', 'attendees.member', 'agendaItems', 'actionItems.responsibleMember']);

            return response()->json([
                'status' => 200,
                'message' => 'Minute updated successfully',
                'data' => $minute,
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'status' => 500,
                'message' => 'Failed to update minute: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Remove the specified minute
     */
    public function destroy($id)
    {
        $minute = Minute::find($id);

        if (!$minute) {
            return response()->json([
                'status' => 404,
                'message' => 'Minute not found',
            ], 404);
        }

        try {
            $minute->delete();

            return response()->json([
                'status' => 200,
                'message' => 'Minute deleted successfully',
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Failed to delete minute: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Upload file for minute attachment
     */
    public function uploadFile(Request $request)
    {
        $validated = $request->validate([
            'file' => 'required|file|max:10240|mimes:pdf,doc,docx,xls,xlsx,ppt,pptx,jpg,jpeg,png,txt',
            'type' => 'required|in:agenda,action',
        ]);

        try {
            $file = $request->file('file');
            $type = $validated['type'];
            
            // Generate unique filename
            $originalName = $file->getClientOriginalName();
            $extension = $file->getClientOriginalExtension();
            $filename = time() . '_' . uniqid() . '.' . $extension;
            
            // Store file in public/minutes/{type} directory
            $path = $file->storeAs("public/minutes/{$type}", $filename);
            
            // Get public URL
            $url = str_replace('public/', 'storage/', $path);
            
            return response()->json([
                'status' => 200,
                'message' => 'File uploaded successfully',
                'data' => [
                    'filename' => $originalName,
                    'stored_name' => $filename,
                    'path' => $url,
                    'size' => $file->getSize(),
                    'mime_type' => $file->getMimeType(),
                ],
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Failed to upload file: ' . $e->getMessage(),
            ], 500);
        }
    }
}
