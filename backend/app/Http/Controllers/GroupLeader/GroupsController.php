<?php

namespace App\Http\Controllers\GroupLeader;

use App\Http\Controllers\Controller;
use App\Models\Member;
use App\Models\Group;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Announcement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class GroupsController extends Controller
{
    /**
     * Get the assigned groups for the group leader
     */
    public function getAssignedGroup(Request $request)
    {
        $user = $request->user();
        $member = Member::where('email', $user->email)->first();
        
        if (!$member || $member->role !== 'group_leader') {
            return response()->json([
                'status' => 403,
                'message' => 'Access denied. Group Leader role required.'
            ], 403);
        }
        
        // Use attribute accessor which handles array conversion and fetching
        $groups = $member->assigned_groups;
        
        if ($groups->isEmpty()) {
            return response()->json([
                'status' => 404,
                'message' => 'No groups assigned to this group leader'
            ], 404);
        }
        
        // Ensure we load the members count for context
        $groups->loadCount('members');
        
        // Backward compatibility: If only one group, return it as 'group'
        // If multiple, return as 'groups' list
        $response = [
            'status' => 200,
            'groups' => $groups,
            'multiple_groups' => $groups->count() > 1
        ];
        
        if ($groups->count() === 1) {
            $response['group'] = $groups->first();
        }
        
        return response()->json($response);
    }

    /**
     * Get all members of the assigned group(s)
     */
    public function getGroupMembers(Request $request)
    {
        $user = $request->user();
        $member = Member::where('email', $user->email)->first();
        
        if (!$member || $member->role !== 'group_leader') {
            return response()->json([
                'status' => 403,
                'message' => 'Access denied. Group Leader role required.'
            ], 403);
        }
        
        $assignedGroupIds = $member->assigned_group_ids ?? [];
        if (is_string($assignedGroupIds)) {
            $assignedGroupIds = json_decode($assignedGroupIds, true) ?? [];
        }
        
        if (empty($assignedGroupIds)) {
            return response()->json([
                'status' => 404,
                'message' => 'No groups assigned to this group leader'
            ], 404);
        }
        
        // Filter by specific group if requested
        $targetGroupIds = $assignedGroupIds;
        if ($request->has('group_id')) {
            $requestedGroupId = (int)$request->group_id;
            if (!in_array($requestedGroupId, $assignedGroupIds)) {
                return response()->json([
                    'status' => 403,
                    'message' => 'You are not assigned to lead the requested group'
                ], 403);
            }
            $targetGroupIds = [$requestedGroupId];
        }
        
        // Get all members who belong to these groups
        $groupMembers = Member::where(function($query) use ($targetGroupIds) {
            foreach ($targetGroupIds as $groupId) {
                $query->orWhere(function($q) use ($groupId) {
                    $q->whereHas('groups', function($subQ) use ($groupId) {
                        $subQ->where('groups.id', $groupId);
                    })
                    ->orWhereRaw('JSON_CONTAINS(groups, ?)', [json_encode($groupId)])
                    ->orWhereRaw('JSON_CONTAINS(groups, ?)', ['"' . $groupId . '"']);
                });
            }
        })
        ->where('id', '!=', $member->id) // Exclude the leader themselves
        ->select(['id', 'full_name', 'email', 'telephone', 'profile_image', 'e_kanisa_number'])
        ->orderBy('full_name')
        ->distinct()
        ->get();
        
        // Helper to get group name(s)
        $groupName = 'Multiple Groups';
        if (count($targetGroupIds) === 1) {
            $group = Group::find($targetGroupIds[0]);
            $groupName = $group ? $group->name : 'Unknown Group'; // Fixed property access
        }
        
        return response()->json([
            'status' => 200,
            'group_id' => count($targetGroupIds) === 1 ? $targetGroupIds[0] : null,
            'group_ids' => $targetGroupIds,
            'group_name' => $groupName,
            'members' => $groupMembers,
            'total_members' => $groupMembers->count()
        ]);
    }

    /**
     * Broadcast message to all group members
     */
    public function broadcastMessage(Request $request)
    {
        $user = $request->user();
        $member = Member::where('email', $user->email)->first();
        
        if (!$member || $member->role !== 'group_leader') {
            return response()->json([
                'status' => 403,
                'message' => 'Access denied. Group Leader role required.'
            ], 403);
        }
        
        $assignedGroupIds = $member->assigned_group_ids ?? [];
        if (is_string($assignedGroupIds)) {
            $assignedGroupIds = json_decode($assignedGroupIds, true) ?? [];
        }

        if (empty($assignedGroupIds)) {
            return response()->json([
                'status' => 404,
                'message' => 'No groups assigned to this group leader'
            ], 404);
        }
        
        $validated = $request->validate([
            'subject' => 'nullable|string|max:255',
            'message' => 'required|string|max:5000',
            'group_id' => 'nullable|integer'
        ]);
        
        // Determine target groups
        $targetGroupIds = $assignedGroupIds;
        if (!empty($validated['group_id'])) {
            $requestedGroupId = (int)$validated['group_id'];
            if (!in_array($requestedGroupId, $assignedGroupIds)) {
                return response()->json([
                    'status' => 403,
                    'message' => 'You are not assigned to lead the requested group'
                ], 403);
            }
            $targetGroupIds = [$requestedGroupId];
        }
        
        // Get all group members for target groups
        $groupMembers = Member::where(function($query) use ($targetGroupIds) {
            foreach ($targetGroupIds as $groupId) {
                $query->orWhere(function($q) use ($groupId) {
                    $q->whereHas('groups', function($subQ) use ($groupId) {
                        $subQ->where('groups.id', $groupId);
                    })
                    ->orWhereRaw('JSON_CONTAINS(groups, ?)', [json_encode($groupId)])
                    ->orWhereRaw('JSON_CONTAINS(groups, ?)', ['"' . $groupId . '"']);
                });
            }
        })
        ->where('id', '!=', $member->id)
        ->distinct()
        ->get();
        
        // Get group name for subject
        $groupName = 'Group Leader'; // Default
        if (count($targetGroupIds) === 1) {
            $group = Group::find($targetGroupIds[0]);
            if ($group) $groupName = $group->name;
        }
        
        $subject = $validated['subject'] ?? 'Message from ' . $groupName;
        $sentCount = 0;
        $conversations = [];
        
        // Create a broadcast announcement
        $broadcastAnnouncement = Announcement::create([
            'title' => $subject,
            'message' => $validated['message'],
            'type' => 'broadcast',
            'sent_by' => $member->id,
            'recipient_id' => null, // Broadcast to all group members
            'is_priority' => false,
            'target_count' => $groupMembers->count(),
        ]);
        
        DB::transaction(function() use ($member, $groupMembers, $validated, $subject, &$sentCount, &$conversations, $broadcastAnnouncement) {
            foreach ($groupMembers as $recipient) {
                // Create individual announcement
                Announcement::create([
                    'title' => $subject,
                    'message' => $validated['message'],
                    'type' => 'individual',
                    'sent_by' => $member->id,
                    'recipient_id' => $recipient->id,
                    'is_priority' => false,
                ]);
                
                // Also create conversation
                $conversation = Conversation::where(function($q) use ($member, $recipient) {
                    $q->where('member_id', $member->id)->where('elder_id', $recipient->id)
                      ->orWhere('member_id', $recipient->id)->where('elder_id', $member->id);
                })->first();
                
                if (!$conversation) {
                    $conversation = Conversation::create([
                        'member_id' => $recipient->id,
                        'elder_id' => $member->id,
                        'subject' => $subject,
                        'status' => 'active',
                        'last_message_at' => now(),
                    ]);
                }
                
                // Create message
                Message::create([
                    'conversation_id' => $conversation->id,
                    'sender_id' => $member->id,
                    'sender_type' => 'member',
                    'message' => $validated['message'],
                    'message_type' => 'text',
                ]);
                
                // Update conversation
                $conversation->update(['last_message_at' => now()]);
                
                // Send SMS notification
                try {
                    if ($recipient->telephone) {
                        $smsService = app(\App\Services\SmsService::class);
                        $smsMessage = "Hello {$recipient->full_name},\n\n";
                        $smsMessage .= "Message from {$member->full_name} ({$subject}):\n\n";
                        $smsMessage .= substr($validated['message'], 0, 100) . (strlen($validated['message']) > 100 ? '...' : '');
                        $smsMessage .= "\n\n- PCEA Church";
                        $smsService->sendSms($recipient->telephone, $smsMessage);
                    }
                } catch (\Exception $e) {
                    \Log::warning('Failed to send SMS for group leader broadcast', ['error' => $e->getMessage()]);
                }
                
                $conversations[] = $conversation->id;
                $sentCount++;
            }
            
            // Broadcast notification event
            try {
                broadcast(new \App\Events\AnnouncementCreated($broadcastAnnouncement));
            } catch (\Exception $e) {
                \Log::warning('Failed to broadcast announcement notification', ['error' => $e->getMessage()]);
            }
        });
        
        return response()->json([
            'status' => 200,
            'message' => "Message broadcasted to {$sentCount} group members",
            'sent_count' => $sentCount,
            'conversations_created' => count($conversations)
        ]);
    }

    /**
     * Send individual message to a group member
     */
    public function sendIndividualMessage(Request $request)
    {
        $user = $request->user();
        $member = Member::where('email', $user->email)->first();
        
        if (!$member || $member->role !== 'group_leader') {
            return response()->json([
                'status' => 403,
                'message' => 'Access denied. Group Leader role required.'
            ], 403);
        }
        
        $assignedGroupIds = $member->assigned_group_ids ?? [];
        if (is_string($assignedGroupIds)) {
            $assignedGroupIds = json_decode($assignedGroupIds, true) ?? [];
        }

        if (empty($assignedGroupIds)) {
            return response()->json([
                'status' => 404,
                'message' => 'No groups assigned to this group leader'
            ], 404);
        }
        
        $validated = $request->validate([
            'recipient_id' => 'required|exists:members,id',
            'subject' => 'nullable|string|max:255',
            'message' => 'required|string|max:5000',
        ]);
        
        // Verify recipient is in ANY of the assigned groups
        $recipient = Member::findOrFail($validated['recipient_id']);
        
        $isMemberOfAssignedGroups = false;
        foreach ($assignedGroupIds as $groupId) {
            if ($recipient->isMemberOfGroup($groupId)) {
                $isMemberOfAssignedGroups = true;
                break;
            }
        }
        
        if (!$isMemberOfAssignedGroups) {
            return response()->json([
                'status' => 403,
                'message' => 'Recipient is not a member of any of your assigned groups'
            ], 403);
        }
        
        // Check if conversation exists
        $conversation = Conversation::where(function($q) use ($member, $recipient) {
            $q->where('member_id', $member->id)->where('elder_id', $recipient->id)
              ->orWhere('member_id', $recipient->id)->where('elder_id', $member->id);
        })->first();
        
        if (!$conversation) {
            $conversation = Conversation::create([
                'member_id' => $recipient->id,
                'elder_id' => $member->id,
                'subject' => $validated['subject'] ?? 'Message from Group Leader',
                'status' => 'active',
                'last_message_at' => now(),
            ]);
        }
        
        // Create announcement
        $announcement = Announcement::create([
            'title' => $validated['subject'] ?? 'Message from Group Leader',
            'message' => $validated['message'],
            'type' => 'individual',
            'sent_by' => $member->id,
            'recipient_id' => $recipient->id,
            'is_priority' => false,
        ]);
        
        // Create message
        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $member->id,
            'sender_type' => 'member',
            'message' => $validated['message'],
            'message_type' => 'text',
        ]);
        
        $conversation->update(['last_message_at' => now()]);
        
        // Send SMS notification
        try {
            if ($recipient->telephone) {
                $smsService = app(\App\Services\SmsService::class);
                $smsMessage = "Hello {$recipient->full_name},\n\n";
                $smsMessage .= "Message from {$member->full_name} (Group Leader):\n\n";
                $smsMessage .= "Subject: " . ($validated['subject'] ?? 'Message') . "\n\n";
                $smsMessage .= $validated['message'];
                $smsMessage .= "\n\n- PCEA Church";
                $smsService->sendSms($recipient->telephone, $smsMessage);
            }
        } catch (\Exception $e) {
            \Log::warning('Failed to send SMS for group leader message', ['error' => $e->getMessage()]);
        }
        
        // Broadcast notification event
        try {
            broadcast(new \App\Events\AnnouncementCreated($announcement));
        } catch (\Exception $e) {
            \Log::warning('Failed to broadcast announcement notification', ['error' => $e->getMessage()]);
        }
        
        $message->load('sender:id,full_name,profile_image');
        
        return response()->json([
            'status' => 200,
            'message' => 'Message sent successfully',
            'conversation_id' => $conversation->id,
            'message_data' => $message
        ], 201);
    }

    /**
     * Get pending join requests for the group leader's groups
     */
    public function getJoinRequests(Request $request)
    {
        $user = $request->user();
        $member = Member::where('email', $user->email)->first();
        
        if (!$member || $member->role !== 'group_leader') {
            return response()->json([
                'status' => 403,
                'message' => 'Access denied. Group Leader role required.'
            ], 403);
        }
        
        $assignedGroupIds = $member->assigned_group_ids ?? [];
        if (is_string($assignedGroupIds)) {
            $assignedGroupIds = json_decode($assignedGroupIds, true) ?? [];
        }
        
        if (empty($assignedGroupIds)) {
            return response()->json([
                'status' => 200, // Return empty list instead of 404
                'requests' => [],
                'count' => 0
            ]);
        }
        
        $requests = \App\Models\GroupJoinRequest::whereIn('group_id', $assignedGroupIds)
            ->where('status', 'pending')
            ->with(['member:id,full_name,email,profile_image,telephone,e_kanisa_number', 'group:id,name'])
            ->orderBy('created_at', 'desc')
            ->get();
            
        return response()->json([
            'status' => 200,
            'requests' => $requests,
            'count' => $requests->count()
        ]);
    }
    
    /**
     * Approve a join request
     */
    public function approveJoinRequest(Request $request, $requestId)
    {
        $user = $request->user();
        $leader = Member::where('email', $user->email)->first();
        
        if (!$leader || $leader->role !== 'group_leader') {
            return response()->json(['status' => 403, 'message' => 'Access denied'], 403);
        }
        
        $joinRequest = \App\Models\GroupJoinRequest::with('member', 'group')->findOrFail($requestId);
        
        // Verify leader is assigned to this group
        $assignedGroupIds = $leader->assigned_group_ids ?? [];
        if (is_string($assignedGroupIds)) {
            $assignedGroupIds = json_decode($assignedGroupIds, true) ?? [];
        }
        
        // Convert to integers for comparison
        $assignedGroupIds = array_map('intval', $assignedGroupIds);
        
        if (!in_array((int)$joinRequest->group_id, $assignedGroupIds)) {
            return response()->json(['status' => 403, 'message' => 'You are not assigned to this group'], 403);
        }
        
        if ($joinRequest->status !== 'pending') {
            return response()->json(['status' => 400, 'message' => 'Request is already processed'], 400);
        }
        
        $member = $joinRequest->member;
        $group = $joinRequest->group;
        
        DB::transaction(function() use ($joinRequest, $member, $group, $leader) {
            // 1. Update request status
            $joinRequest->update(['status' => 'approved']);
            
            // 2. Add member to group
            // Handle both structure types for backward compatibility
            // Try updating pivot first if relation exists, but since we use raw JSON/Pivot mix:
            
            // Update JSON 'groups' column if it exists or used
            $currentGroups = [];
            if ($member->groups) {
                try {
                    $decoded = is_string($member->groups) ? json_decode($member->groups, true) : $member->groups;
                    if (is_array($decoded)) $currentGroups = $decoded;
                } catch (\Exception $e) {}
            }
            
            // Also check pivot to ensure we are up to date
            $pivotGroups = $member->groups()->pluck('groups.id')->toArray();
            $allGroups = array_unique(array_merge($currentGroups, $pivotGroups));
            
            if (!in_array($group->id, $allGroups)) {
                // Attach via pivot (preferred way now)
                $member->groups()->attach($group->id);
                
                // Also update JSON for legacy support if needed, but best to stick to one. 
                // Given existing code reads both, updating pivot is safer.
                // However, previous code updated 'assigned_group_ids' for members (Wait, members table has 'groups' ? No, 'groups' column).
                // Let's check Member model. Existing code usually does: $member->groups()->attach($groupId);
                // But migration added `assigned_group_ids`. Wait, `assigned_group_ids` is for LEADERS. 
                // Regular members use `groups` column (JSON) or pivot `group_member` table.
                // Looking at `Member::isMemberOfGroup`: checked both JSON `groups` column AND pivot.
                
                // Let's update pivot.
                // If the app relies on the JSON column `groups` (not `assigned_group_ids`), we should update that too to be safe.
                $allGroups[] = $group->id;
                $member->groups = json_encode(array_values(array_unique($allGroups)));
                $member->save();
            }
            
            // 3. Notify Member (SMS + Announcement)
            // Announcement
            $title = "Group Join Request Approved";
            $message = "Your request to join '{$group->name}' has been approved by {$leader->full_name}.";
            
            Announcement::create([
                'title' => $title,
                'message' => $message,
                'type' => 'individual',
                'sent_by' => $leader->id,
                'recipient_id' => $member->id,
                'is_priority' => false,
            ]);
            
            // SMS
            try {
                if ($member->telephone) {
                    $smsService = app(\App\Services\SmsService::class);
                    $smsMessage = "Hello {$member->full_name},\n\nYour request to join '{$group->name}' has been APPROVED.\n\nWelcome to the group!\n\n- PCEA Church";
                    $smsService->sendSms($member->telephone, $smsMessage);
                }
            } catch (\Exception $e) {
                \Log::warning('Failed to send SMS for approved join request', ['error' => $e->getMessage()]);
            }
        });
        
        return response()->json([
            'status' => 200,
            'message' => 'Request approved successfully. Member has been added.',
        ]);
    }
}

