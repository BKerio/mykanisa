<?php

namespace App\Http\Controllers\Member;

use App\Http\Controllers\Controller;
use App\Models\Member;
use App\Models\Group;
use Illuminate\Http\Request;

class GroupsController extends Controller
{
    /**
     * Get the group leader assigned to the member's group
     */
    public function getMyGroupLeader(Request $request)
    {
        $user = $request->user();
        $member = Member::where('email', $user->email)->first();
        
        if (!$member) {
            return response()->json([
                'status' => 404,
                'message' => 'Member not found'
            ], 404);
        }
        
        // Get member's groups
        $memberGroupIds = [];
        if ($member->groups) {
            try {
                $decoded = is_string($member->groups) ? json_decode($member->groups, true) : $member->groups;
                if (is_array($decoded)) {
                    $memberGroupIds = $decoded;
                }
            } catch (\Exception $e) {
                // Invalid JSON, try pivot table
            }
        }
        
        // Also check pivot table
        $memberGroups = $member->groups()->pluck('groups.id')->toArray();
        $memberGroupIds = array_unique(array_merge($memberGroupIds, $memberGroups));
        
        if (empty($memberGroupIds)) {
            return response()->json([
                'status' => 404,
                'message' => 'You are not a member of any group',
                'group_leader' => null
            ]);
        }
        
        // Find group leader assigned to any of the member's groups
        // We need to check if ANY of the member's group IDs are in the leader's assigned_group_ids JSON array
        $groupLeader = Member::where('role', 'group_leader')
            ->where(function ($query) use ($memberGroupIds) {
                foreach ($memberGroupIds as $groupId) {
                    $query->orWhereRaw('JSON_CONTAINS(assigned_group_ids, ?)', [json_encode((int)$groupId)])
                          ->orWhereRaw('JSON_CONTAINS(assigned_group_ids, ?)', ['"' . $groupId . '"']);
                }
            })
            ->first();
        
        if (!$groupLeader) {
            return response()->json([
                'status' => 404,
                'message' => 'No group leader assigned to your group(s)',
                'group_leader' => null
            ]);
        }
        
        // Determine which group matches (context)
        $leaderAssignedIds = $groupLeader->assigned_group_ids ?? [];
        if (is_string($leaderAssignedIds)) {
            $leaderAssignedIds = json_decode($leaderAssignedIds, true) ?? [];
        }
        
        // Find the common group ID
        $commonGroupId = null;
        foreach ($memberGroupIds as $mId) {
            if (in_array((int)$mId, array_map('intval', $leaderAssignedIds))) {
                $commonGroupId = $mId;
                break;
            }
        }
        
        $assignedGroup = null;
        if ($commonGroupId) {
            $assignedGroup = Group::find($commonGroupId);
        }
        
        return response()->json([
            'status' => 200,
            'group_leader' => [
                'id' => $groupLeader->id,
                'full_name' => $groupLeader->full_name,
                'email' => $groupLeader->email,
                'telephone' => $groupLeader->telephone,
                'profile_image' => $groupLeader->profile_image,
                'assigned_group' => $assignedGroup, // Contextual group
            ]
        ]);
    }

    /**
     * Send a message to the group leader
     */
    public function sendMessageToGroupLeader(Request $request)
    {
        $user = $request->user();
        
        // Get member ID
        $memberId = null;
        $member = null;
        if ($user instanceof Member) {
            $memberId = $user->id;
            $member = $user;
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

        $validated = $request->validate([
            'group_leader_id' => 'required|exists:members,id',
            'title' => 'required|string|max:255',
            'message' => 'required|string|max:5000',
        ]);

        // Verify the recipient is a group leader and is assigned to the member's group
        $groupLeader = Member::findOrFail($validated['group_leader_id']);
        $groupLeaderRole = strtolower(trim($groupLeader->role ?? 'member'));
        if ($groupLeaderRole !== 'group_leader') {
            return response()->json([
                'status' => 403,
                'message' => 'The recipient must be a group leader'
            ], 403);
        }

        // Verify the group leader is assigned to a group the member belongs to
        $memberGroupIds = [];
        if ($member->groups) {
            try {
                $decoded = is_string($member->groups) ? json_decode($member->groups, true) : $member->groups;
                if (is_array($decoded)) {
                    $memberGroupIds = $decoded;
                }
            } catch (\Exception $e) {
                // Invalid JSON, try pivot table
            }
        }
        
        // Also check pivot table
        $memberGroups = $member->groups()->pluck('groups.id')->toArray();
        $memberGroupIds = array_unique(array_merge($memberGroupIds, $memberGroups));
        
        // Check if group leader is assigned to ANY of the member's groups
        $leaderAssignedIds = $groupLeader->assigned_group_ids ?? [];
        if (is_string($leaderAssignedIds)) {
            $leaderAssignedIds = json_decode($leaderAssignedIds, true) ?? [];
        }
        
        $hasCommonGroup = false;
        foreach ($memberGroupIds as $mId) {
            if (in_array((int)$mId, array_map('intval', $leaderAssignedIds))) {
                $hasCommonGroup = true;
                break;
            }
        }

        if (!$hasCommonGroup) {
            return response()->json([
                'status' => 403,
                'message' => 'The group leader is not assigned to any of your groups'
            ], 403);
        }

        // Create the message using Announcement model (similar to elder messaging)
        $announcement = \App\Models\Announcement::create([
            'title' => $validated['title'],
            'message' => $validated['message'],
            'type' => 'individual',
            'sent_by' => $memberId, // Member is sending
            'recipient_id' => $validated['group_leader_id'], // Group leader is receiving
            'is_priority' => false,
        ]);

        // Send SMS to group leader if they have a phone number
        try {
            if ($groupLeader->telephone) {
                $smsService = app(\App\Services\SmsService::class);
                $memberName = $member->full_name ?? 'Member';
                $smsMessage = "Hello {$groupLeader->full_name},\n\n";
                $smsMessage .= "Message from {$memberName}:\n\n";
                $smsMessage .= "Subject: {$validated['title']}\n\n";
                $smsMessage .= $validated['message'];
                $smsMessage .= "\n\n- PCEA Church";
                $smsService->sendSms($groupLeader->telephone, $smsMessage);
            }
        } catch (\Exception $e) {
            \Log::warning('Failed to send SMS for member message to group leader', ['error' => $e->getMessage()]);
        }

        $announcement->load(['sender' => function($query) {
            $query->select('id', 'full_name', 'email', 'role');
        }]);

        // Broadcast notification event
        try {
            broadcast(new \App\Events\AnnouncementCreated($announcement));
        } catch (\Exception $e) {
            \Log::warning('Failed to broadcast announcement notification', ['error' => $e->getMessage()]);
        }

        return response()->json([
            'status' => 200,
            'message' => 'Message sent to group leader successfully',
            'announcement' => $announcement,
        ], 201);
    }

    /**
     * Get all activities for a specific group
     */
    public function getGroupActivities(Request $request, $groupId)
    {
        $user = $request->user();
        $member = Member::where('email', $user->email)->first();
        
        if (!$member) {
            return response()->json([
                'status' => 404,
                'message' => 'Member not found'
            ], 404);
        }

        // Verify member belongs to this group
        $memberGroupIds = [];
        if ($member->groups) {
            try {
                $decoded = json_decode($member->groups, true);
                if (is_array($decoded)) {
                    $memberGroupIds = $decoded;
                }
            } catch (\Exception $e) {
                // Invalid JSON, try pivot table
            }
        }
        
        // Also check pivot table
        $memberGroups = $member->groups()->pluck('groups.id')->toArray();
        $memberGroupIds = array_unique(array_merge($memberGroupIds, $memberGroups));
        
        if (!in_array((int)$groupId, $memberGroupIds)) {
            return response()->json([
                'status' => 403,
                'message' => 'You are not a member of this group'
            ], 403);
        }

        // Get group details
        $group = Group::with('members:id,full_name,email,telephone,profile_image,role')
            ->findOrFail($groupId);

        // Get group leader for this group
        // We need to check if this specific group ID is in anyone's assigned_group_ids
        $groupLeader = Member::where('role', 'group_leader')
            ->where(function ($query) use ($groupId) {
                $query->whereRaw('JSON_CONTAINS(assigned_group_ids, ?)', [json_encode((int)$groupId)])
                      ->orWhereRaw('JSON_CONTAINS(assigned_group_ids, ?)', ['"' . $groupId . '"']);
            })
            ->first();
            
        // Note: We don't eager load "assignedGroup" anymore since it's now many-to-many via JSON
        // Instead we can assign the context group manually for the response
        if ($groupLeader) {
            $groupLeader->context_group = $group; // Reuse the group we already fetched
        }

        // Get group members (from pivot table)
        // Only return members if the requesting user is the group leader for this group
        $isLeader = false;
        $groupMembers = collect([]);
        
        if ($groupLeader && $groupLeader->id === $member->id) {
            $isLeader = true;
            $groupMembers = $group->members()
                ->select('members.id', 'members.full_name', 'members.email', 'members.telephone', 'members.profile_image', 'members.role', 'members.e_kanisa_number')
                ->where('members.is_active', true)
                ->orderBy('members.full_name')
                ->get();
        }

        // Get announcements/messages related to this group
        // Get both broadcast announcements from group leader and individual messages to/from the member
        $announcements = [];
        
        if ($groupLeader) {
            // Get broadcast announcements from group leader
            $broadcastAnnouncements = \App\Models\Announcement::where('sent_by', $groupLeader->id)
                ->where('type', 'broadcast')
                ->orderBy('created_at', 'desc')
                ->with(['sender:id,full_name,profile_image'])
                ->get();
            
            // Get individual messages between member and group leader
            $individualAnnouncements = \App\Models\Announcement::where(function($query) use ($member, $groupLeader) {
                $query->where(function($q) use ($member, $groupLeader) {
                    // Messages from group leader to member
                    $q->where('sent_by', $groupLeader->id)
                      ->where('recipient_id', $member->id);
                })->orWhere(function($q) use ($member, $groupLeader) {
                    // Messages from member to group leader
                    $q->where('sent_by', $member->id)
                      ->where('recipient_id', $groupLeader->id);
                });
            })
            ->where('type', 'individual')
            ->orderBy('created_at', 'desc')
            ->with(['sender:id,full_name,profile_image'])
            ->get();
            
            // Combine and sort by date
            $announcements = $broadcastAnnouncements->concat($individualAnnouncements)
                ->sortByDesc('created_at')
                ->take(20)
                ->values();
        }

        // Get events (placeholder - you may need to implement group-specific events)
        $events = [];

        return response()->json([
            'status' => 200,
            'group' => [
                'id' => $group->id,
                'name' => $group->name,
                'description' => $group->description,
            ],
            'group_leader' => $groupLeader ? [
                'id' => $groupLeader->id,
                'full_name' => $groupLeader->full_name,
                'email' => $groupLeader->email,
                'telephone' => $groupLeader->telephone,
                'profile_image' => $groupLeader->profile_image,
            ] : null,
            'members' => $groupMembers->map(function($m) {
                return [
                    'id' => $m->id,
                    'full_name' => $m->full_name,
                    'email' => $m->email,
                    'telephone' => $m->telephone,
                    'profile_image' => $m->profile_image,
                    'role' => $m->role,
                    'e_kanisa_number' => $m->e_kanisa_number,
                ];
            }),
            'member_count' => $isLeader ? $groupMembers->count() : 0, // Only return count for leaders
            'is_leader' => $isLeader, // Indicate if requesting user is the leader
            'announcements' => $announcements->map(function($a) {
                return [
                    'id' => $a->id,
                    'title' => $a->title,
                    'message' => $a->message,
                    'created_at' => $a->created_at,
                    'sender' => $a->sender ? [
                        'id' => $a->sender->id,
                        'full_name' => $a->sender->full_name,
                        'profile_image' => $a->sender->profile_image,
                    ] : null,
                ];
            }),
            'events' => $events, // Placeholder for future implementation
        ]);
    }
    /**
     * Request to join a group
     */
    public function requestJoinGroup(Request $request)
    {
        $user = $request->user();
        if ($user instanceof Member) {
            $member = $user;
        } else {
            $member = Member::where('email', $user->email)->first();
        }

        if (!$member) {
            return response()->json([
                'status' => 404,
                'message' => 'Member not found'
            ], 404);
        }

        $validated = $request->validate([
            'group_id' => 'required|exists:groups,id'
        ]);
        
        $groupId = $validated['group_id'];
        $group = Group::findOrFail($groupId);

        // Check if already a member
        $isMember = $member->isMemberOfGroup($groupId);
        if ($isMember) {
            return response()->json([
                'status' => 400,
                'message' => 'You are already a member of this group'
            ], 400);
        }

        // Check if pending request exists
        $existingRequest = \App\Models\GroupJoinRequest::where('member_id', $member->id)
            ->where('group_id', $groupId)
            ->where('status', 'pending')
            ->first();

        if ($existingRequest) {
            return response()->json([
                'status' => 400,
                'message' => 'You already have a pending request to join this group'
            ], 400);
        }

        // Create new request
        \App\Models\GroupJoinRequest::create([
            'member_id' => $member->id,
            'group_id' => $groupId,
            'status' => 'pending'
        ]);

        // Find Group Leader(s) for this group
        // Check assigned_group_ids JSON
        $groupLeaders = Member::where('role', 'group_leader')
            ->where(function ($query) use ($groupId) {
                $query->whereRaw('JSON_CONTAINS(assigned_group_ids, ?)', [json_encode((int)$groupId)])
                      ->orWhereRaw('JSON_CONTAINS(assigned_group_ids, ?)', ['"' . $groupId . '"']);
            })
            ->get();

        $sentCount = 0;
        if (!$groupLeaders->isEmpty()) {
            foreach ($groupLeaders as $leader) {
                // Create in-app notification (Announcement)
                $title = "Group Join Request: {$group->name}";
                $message = "Member {$member->full_name} has requested to join your group '{$group->name}'. Please go to your dashboard to approve or reject this request.";
                
                $announcement = \App\Models\Announcement::create([
                    'title' => $title,
                    'message' => $message,
                    'type' => 'individual',
                    'sent_by' => $member->id,
                    'recipient_id' => $leader->id,
                    'is_priority' => true,
                ]);

                // Send SMS
                try {
                    if ($leader->telephone) {
                        $smsService = app(\App\Services\SmsService::class);
                        $smsMessage = "Hello {$leader->full_name},\n\n{$member->full_name} has requested to join your group '{$group->name}'.\n\nPlease log in to the app to approve or reject.\n\n- PCEA Church";
                        $smsService->sendSms($leader->telephone, $smsMessage);
                        $sentCount++;
                    }
                } catch (\Exception $e) {
                    \Log::warning("Failed to send SMS to leader {$leader->id}", ['error' => $e->getMessage()]);
                }
            }
        }

        return response()->json([
            'status' => 200,
            'message' => "Join request submitted successfully.",
        ]);
    }

    /**
     * Get the authenticated member's pending join requests
     */
    public function getMyPendingRequests(Request $request)
    {
        $user = $request->user();
        if ($user instanceof Member) {
            $member = $user;
        } else {
            $member = Member::where('email', $user->email)->first();
        }

        if (!$member) {
            return response()->json([
                'status' => 404,
                'message' => 'Member not found'
            ], 404);
        }

        // Get all pending requests for this member
        $pendingRequests = \App\Models\GroupJoinRequest::where('member_id', $member->id)
            ->where('status', 'pending')
            ->pluck('group_id')
            ->toArray();

        return response()->json([
            'status' => 200,
            'pending_group_ids' => $pendingRequests,
        ]);
    }
}

