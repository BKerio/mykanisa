<?php

namespace App\Http\Controllers;

use App\Models\Member;
use App\Models\Minute;
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
}


