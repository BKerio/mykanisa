<?php

namespace App\Http\Controllers;

use App\Models\Member;
use App\Models\Minute;
use App\Models\MinuteActionItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;

class MinutesController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'meetingType' => 'required|string',
            'date' => 'required|date',
            'minuteNumber' => 'required|string|unique:minutes,minute_number',
            'agendas' => 'required|array|min:1',
            'agendaDetails' => 'nullable|array',
            // Either names or ids can be provided
            'present' => 'nullable|array',
            'apologies' => 'nullable|array',
            'present_ids' => 'nullable|array',
            'present_ids.*' => 'integer',
            'apology_ids' => 'nullable|array',
            'apology_ids.*' => 'integer',
            'agendaTitleFilter' => 'nullable|string',
            'content' => 'nullable|string',
        ]);

        $user = $request->user();
        $congregation = Member::where('email', $user?->email)->value('congregation');

        return DB::transaction(function () use ($validated, $user, $congregation) {
            $minute = Minute::create([
                'meeting_type' => $validated['meetingType'],
                'meeting_date' => $validated['date'],
                'minute_number' => $validated['minuteNumber'],
                'agenda_title_filter' => $validated['agendaTitleFilter'] ?? null,
                'content' => $validated['content'] ?? null,
                'agendas_json' => json_encode($validated['agendas']),
                'agenda_details_json' => json_encode($validated['agendaDetails'] ?? new \stdClass()),
                'created_by_user_id' => $user?->id,
                'congregation' => $congregation,
            ]);

            // Attach attendees
            $namesToIds = function (array $names) {
                return Member::whereIn('full_name', $names)->pluck('id', 'full_name');
            };

            // Prefer IDs when provided
            $presentIds = $validated['present_ids'] ?? [];
            $apologyIds = $validated['apology_ids'] ?? [];

            if (empty($presentIds) && !empty($validated['present'])) {
                $presentMap = $namesToIds($validated['present']);
                $presentIds = array_values($presentMap->toArray());
            }
            if (empty($apologyIds) && !empty($validated['apologies'])) {
                $apologyIds = Member::whereIn('full_name', $validated['apologies'])->pluck('id')->toArray();
            }

            foreach ($presentIds as $pid) {
                if ($pid) {
                    $minute->attendees()->syncWithoutDetaching([$pid => ['status' => 'present']]);
                }
            }
            foreach ($apologyIds as $aid) {
                if ($aid) {
                    $minute->attendees()->syncWithoutDetaching([$aid => ['status' => 'apology']]);
                }
            }

            return response()->json([
                'status' => 201,
                'message' => 'Minutes created',
                'minute' => $minute,
            ], 201);
        });
    }

    public function mine(Request $request)
    {
        $user = $request->user();
        // user table (users) vs members table. 
        // Assuming user->email links to member->email or there is a link.
        // User model usually has 'member_id' or we lookup by email.
        // Based on existing code: Member::where('email', $user?->email)->first();
        
        $member = Member::where('email', $user?->email)->first();
        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member record not found'], 404);
        }

        // Get minutes where member is attendee (present or apology)
        $minutes = Minute::with(['creator', 'attendees.member', 'agendaItems', 'actionItems'])
            ->whereHas('attendees', function ($q) use ($member) {
                $q->where('member_id', $member->id)
                  ->whereIn('status', ['present', 'absent_with_apology']);
            })
            ->orderBy('meeting_date', 'desc')
            ->orderBy('meeting_time', 'desc')
            ->paginate(15);

        return response()->json([
            'status' => 200,
            'message' => 'My minutes retrieved successfully',
            'data' => $minutes,
        ]);
    }

    public function show($id)
    {
        $user = request()->user();
        $member = Member::where('email', $user?->email)->first();
        
        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        $minute = Minute::with(['creator', 'attendees.member', 'agendaItems', 'actionItems.responsibleMember'])
            ->where('id', $id)
            ->whereHas('attendees', function ($q) use ($member) {
                $q->where('member_id', $member->id)
                  ->whereIn('status', ['present', 'absent_with_apology']);
            })
            ->first();

        if (!$minute) {
            return response()->json(['status' => 403, 'message' => 'Unauthorized or Minute not found'], 403);
        }

        return response()->json([
            'status' => 200,
            'data' => $minute,
        ]);
    }

    public function updateActionStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:Pending,In progress,Done,Cannot Manage', // "Cannot Manage" might need to be added to enum or handled? Wait, DB enum!
            'status_reason' => 'nullable|string',
        ]);

        // DB Enum is ['Pending', 'In progress', 'Done']. I need to check if I can add 'Cannot Manage'. 
        // Or "Cannot Manage" is a status reason? User said "mark it done, not yet done or can not manage".
        // If I can't change enum easily without migration (I can, but I just ran one).
        // I should probably update the enum in the migration too? Or map "Cannot Manage" to "Pending" with reason?
        // User explicitly said "mark it... can not manage". 
        // I will stick to existing enums if possible or Update Enum.
        // Actually, simple solution: "In progress" = Not yet done. "Done" = Done. "Pending"?
        // "Cannot Manage" effectively means they are rejecting it.
        // I will try to update the enum in database migration if I can, OR just use "Pending" with status_reason "Cannot Manage".
        // But better UX is to have the status.
        // Let's assume for now I will use "Pending" + Reason = "Cannot Manage" or "In progress". 
        // Wait, the user wants to "mark it... cannot manage".
        // I'll check the DB Schema again. Step 748: `enum('status', ['Pending', 'In progress', 'Done'])`.
        // I should probably add 'Cannot Manage' to the Enum.
        // BUT changing enum in Doctrine/Laravel is tricky.
        // Workaround: Use 'Pending' or 'In progress' with a specific reason. 
        // OR add it.
        // I'll try to add it using raw SQL in a migration if needed, but for now let's use the existing statuses and maybe 'Pending' implies 'Cannot Manage' if reason is set?
        // No, that's ambiguous.
        // Let's rely on 'status_reason' text.
        // "mark it done, not yet done or can not manage".
        // Done -> Done.
        // Not yet done -> In progress.
        // Cannot manage -> Pending (with reason)? Or maybe I should just let them write the status in text if I can't change enum.
        // I'll stick to updating the Status Reason mainly, and mapping the user's intent to DB status.
        // User intent:
        // 1. Done -> DB: Done.
        // 2. Not yet done -> DB: In progress.
        // 3. Cannot manage -> DB: Pending (or maybe I should add a status).
        // Let's just allow updating status and reason.
        
        $item = MinuteActionItem::find($id);
        if (!$item) {
            return response()->json(['status' => 404, 'message' => 'Task not found'], 404);
        }

        $user = request()->user();
        $member = Member::where('email', $user?->email)->first();

        if (!$member || ($item->responsible_member_id != $member->id)) {
            // Also allow if user is secretary? (Not checked here, strict to assignee for now as per "member who they've been assigned... can update")
            return response()->json(['status' => 403, 'message' => 'Unauthorized'], 403);
        }

        $status = $request->status;
        $reason = $request->status_reason;

        // Map "Cannot Manage" to a valid DB status
        if ($status === 'Cannot Manage') {
            $status = 'Pending'; 
            $reason = "[Cannot Manage] " . ($reason ?? '');
        }

        $item->status = $status;
        $item->status_reason = $reason;
        $item->save();

        return response()->json(['status' => 200, 'message' => 'Task updated successfully']);
    }
}


