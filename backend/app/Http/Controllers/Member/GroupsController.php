<?php

namespace App\Http\Controllers\Member;

use App\Http\Controllers\Controller;
use App\Models\Member;
use App\Models\Group;
use Illuminate\Http\Request;

class GroupsController extends Controller
{
    /**
     * Get the youth leader assigned to the member's group
     */
    public function getMyYouthLeader(Request $request)
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
        
        if (empty($memberGroupIds)) {
            return response()->json([
                'status' => 404,
                'message' => 'You are not a member of any group',
                'youth_leader' => null
            ]);
        }
        
        // Find youth leader assigned to any of the member's groups
        $youthLeader = Member::where('role', 'youth_leader')
            ->whereIn('assigned_group_id', $memberGroupIds)
            ->with(['assignedGroup:id,name,description'])
            ->first();
        
        if (!$youthLeader) {
            return response()->json([
                'status' => 404,
                'message' => 'No youth leader assigned to your group(s)',
                'youth_leader' => null
            ]);
        }
        
        return response()->json([
            'status' => 200,
            'youth_leader' => [
                'id' => $youthLeader->id,
                'full_name' => $youthLeader->full_name,
                'email' => $youthLeader->email,
                'telephone' => $youthLeader->telephone,
                'profile_image' => $youthLeader->profile_image,
                'assigned_group' => $youthLeader->assignedGroup,
            ]
        ]);
    }

    /**
     * Send a message to the youth leader
     */
    public function sendMessageToYouthLeader(Request $request)
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
            'youth_leader_id' => 'required|exists:members,id',
            'title' => 'required|string|max:255',
            'message' => 'required|string|max:5000',
        ]);

        // Verify the recipient is a youth leader and is assigned to the member's group
        $youthLeader = Member::findOrFail($validated['youth_leader_id']);
        $youthLeaderRole = strtolower(trim($youthLeader->role ?? 'member'));
        if ($youthLeaderRole !== 'youth_leader') {
            return response()->json([
                'status' => 403,
                'message' => 'The recipient must be a youth leader'
            ], 403);
        }

        // Verify the youth leader is assigned to a group the member belongs to
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
        
        if (!$youthLeader->assigned_group_id || !in_array($youthLeader->assigned_group_id, $memberGroupIds)) {
            return response()->json([
                'status' => 403,
                'message' => 'The youth leader is not assigned to any of your groups'
            ], 403);
        }

        // Create the message using Announcement model (similar to elder messaging)
        $announcement = \App\Models\Announcement::create([
            'title' => $validated['title'],
            'message' => $validated['message'],
            'type' => 'individual',
            'sent_by' => $memberId, // Member is sending
            'recipient_id' => $validated['youth_leader_id'], // Youth leader is receiving
            'is_priority' => false,
        ]);

        // Send SMS to youth leader if they have a phone number
        try {
            if ($youthLeader->telephone) {
                $smsService = app(\App\Services\SmsService::class);
                $memberName = $member->full_name ?? 'Member';
                $smsMessage = "Hello {$youthLeader->full_name},\n\n";
                $smsMessage .= "Message from {$memberName}:\n\n";
                $smsMessage .= "Subject: {$validated['title']}\n\n";
                $smsMessage .= $validated['message'];
                $smsMessage .= "\n\n- PCEA Church";
                $smsService->sendSms($youthLeader->telephone, $smsMessage);
            }
        } catch (\Exception $e) {
            \Log::warning('Failed to send SMS for member message to youth leader', ['error' => $e->getMessage()]);
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
            'message' => 'Message sent to youth leader successfully',
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

        // Get youth leader for this group
        $youthLeader = Member::where('role', 'youth_leader')
            ->where('assigned_group_id', $groupId)
            ->with(['assignedGroup:id,name,description'])
            ->first();

        // Get group members (from pivot table)
        // Only return members if the requesting user is the youth leader for this group
        $isLeader = false;
        $groupMembers = collect([]);
        
        if ($youthLeader && $youthLeader->id === $member->id) {
            $isLeader = true;
            $groupMembers = $group->members()
                ->select('members.id', 'members.full_name', 'members.email', 'members.telephone', 'members.profile_image', 'members.role', 'members.e_kanisa_number')
                ->where('members.is_active', true)
                ->orderBy('members.full_name')
                ->get();
        }

        // Get announcements/messages related to this group
        // Get both broadcast announcements from youth leader and individual messages to/from the member
        $announcements = [];
        
        if ($youthLeader) {
            // Get broadcast announcements from youth leader
            $broadcastAnnouncements = \App\Models\Announcement::where('sent_by', $youthLeader->id)
                ->where('type', 'broadcast')
                ->orderBy('created_at', 'desc')
                ->with(['sender:id,full_name,profile_image'])
                ->get();
            
            // Get individual messages between member and youth leader
            $individualAnnouncements = \App\Models\Announcement::where(function($query) use ($member, $youthLeader) {
                $query->where(function($q) use ($member, $youthLeader) {
                    // Messages from youth leader to member
                    $q->where('sent_by', $youthLeader->id)
                      ->where('recipient_id', $member->id);
                })->orWhere(function($q) use ($member, $youthLeader) {
                    // Messages from member to youth leader
                    $q->where('sent_by', $member->id)
                      ->where('recipient_id', $youthLeader->id);
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
            'youth_leader' => $youthLeader ? [
                'id' => $youthLeader->id,
                'full_name' => $youthLeader->full_name,
                'email' => $youthLeader->email,
                'telephone' => $youthLeader->telephone,
                'profile_image' => $youthLeader->profile_image,
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
}

