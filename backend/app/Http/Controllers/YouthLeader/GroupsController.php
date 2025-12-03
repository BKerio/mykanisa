<?php

namespace App\Http\Controllers\YouthLeader;

use App\Http\Controllers\Controller;
use App\Models\Member;
use App\Models\Group;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Announcement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class GroupsController extends Controller
{
    /**
     * Get the assigned group for the youth leader
     */
    public function getAssignedGroup(Request $request)
    {
        $user = $request->user();
        $member = Member::where('email', $user->email)->first();
        
        if (!$member || $member->role !== 'youth_leader') {
            return response()->json([
                'status' => 403,
                'message' => 'Access denied. Youth Leader role required.'
            ], 403);
        }
        
        if (!$member->assigned_group_id) {
            return response()->json([
                'status' => 404,
                'message' => 'No group assigned to this youth leader'
            ], 404);
        }
        
        $group = $member->assignedGroup()->with('members')->first();
        
        return response()->json([
            'status' => 200,
            'group' => $group
        ]);
    }

    /**
     * Get all members of the assigned group
     */
    public function getGroupMembers(Request $request)
    {
        $user = $request->user();
        $member = Member::where('email', $user->email)->first();
        
        if (!$member || $member->role !== 'youth_leader') {
            return response()->json([
                'status' => 403,
                'message' => 'Access denied. Youth Leader role required.'
            ], 403);
        }
        
        if (!$member->assigned_group_id) {
            return response()->json([
                'status' => 404,
                'message' => 'No group assigned to this youth leader'
            ], 404);
        }
        
        // Get all members who belong to this group
        // Check both pivot table and JSON field
        $groupMembers = Member::where(function($query) use ($member) {
            // Check pivot table relationship
            $query->whereHas('groups', function($q) use ($member) {
                $q->where('groups.id', $member->assigned_group_id);
            })
            ->orWhere(function($q) use ($member) {
                // Also check the JSON groups field
                $groupId = $member->assigned_group_id;
                $q->whereRaw('JSON_CONTAINS(groups, ?)', [json_encode($groupId)])
                  ->orWhereRaw('JSON_CONTAINS(groups, ?)', ['"' . $groupId . '"']);
            });
        })
        ->where('id', '!=', $member->id) // Exclude the youth leader themselves
        ->select(['id', 'full_name', 'email', 'telephone', 'profile_image', 'e_kanisa_number'])
        ->orderBy('full_name')
        ->get();
        
        return response()->json([
            'status' => 200,
            'group_id' => $member->assigned_group_id,
            'group_name' => $member->assignedGroup->name ?? 'Unknown Group',
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
        
        if (!$member || $member->role !== 'youth_leader') {
            return response()->json([
                'status' => 403,
                'message' => 'Access denied. Youth Leader role required.'
            ], 403);
        }
        
        if (!$member->assigned_group_id) {
            return response()->json([
                'status' => 404,
                'message' => 'No group assigned to this youth leader'
            ], 404);
        }
        
        $validated = $request->validate([
            'subject' => 'nullable|string|max:255',
            'message' => 'required|string|max:5000',
        ]);
        
        // Get all group members
        $groupMembers = Member::where(function($query) use ($member) {
            // Check pivot table relationship
            $query->whereHas('groups', function($q) use ($member) {
                $q->where('groups.id', $member->assigned_group_id);
            })
            ->orWhere(function($q) use ($member) {
                // Also check the JSON groups field
                $groupId = $member->assigned_group_id;
                $q->whereRaw('JSON_CONTAINS(groups, ?)', [json_encode($groupId)])
                  ->orWhereRaw('JSON_CONTAINS(groups, ?)', ['"' . $groupId . '"']);
            });
        })
        ->where('id', '!=', $member->id)
        ->get();
        
        $subject = $validated['subject'] ?? 'Message from ' . ($member->assignedGroup->name ?? 'Youth Leader');
        $sentCount = 0;
        $conversations = [];
        
        // Create a broadcast announcement for group activities visibility
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
                // Create individual announcement for each member for their inbox
                Announcement::create([
                    'title' => $subject,
                    'message' => $validated['message'],
                    'type' => 'individual',
                    'sent_by' => $member->id,
                    'recipient_id' => $recipient->id,
                    'is_priority' => false,
                ]);
                
                // Also create conversation for real-time messaging
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
                        $smsMessage .= "Message from {$member->full_name} (Youth Leader):\n\n";
                        $smsMessage .= "Subject: {$subject}\n\n";
                        $smsMessage .= $validated['message'];
                        $smsMessage .= "\n\n- PCEA Church";
                        $smsService->sendSms($recipient->telephone, $smsMessage);
                    }
                } catch (\Exception $e) {
                    \Log::warning('Failed to send SMS for youth leader broadcast', ['error' => $e->getMessage()]);
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
        
        if (!$member || $member->role !== 'youth_leader') {
            return response()->json([
                'status' => 403,
                'message' => 'Access denied. Youth Leader role required.'
            ], 403);
        }
        
        if (!$member->assigned_group_id) {
            return response()->json([
                'status' => 404,
                'message' => 'No group assigned to this youth leader'
            ], 404);
        }
        
        $validated = $request->validate([
            'recipient_id' => 'required|exists:members,id',
            'subject' => 'nullable|string|max:255',
            'message' => 'required|string|max:5000',
        ]);
        
        // Verify recipient is in the assigned group
        $recipient = Member::findOrFail($validated['recipient_id']);
        
        if (!$recipient->isMemberOfGroup($member->assigned_group_id)) {
            return response()->json([
                'status' => 403,
                'message' => 'Recipient is not a member of your assigned group'
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
                'subject' => $validated['subject'] ?? 'Message from Youth Leader',
                'status' => 'active',
                'last_message_at' => now(),
            ]);
        }
        
        // Create announcement for inbox visibility
        $announcement = Announcement::create([
            'title' => $validated['subject'] ?? 'Message from Youth Leader',
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
                $smsMessage .= "Message from {$member->full_name} (Youth Leader):\n\n";
                $smsMessage .= "Subject: " . ($validated['subject'] ?? 'Message') . "\n\n";
                $smsMessage .= $validated['message'];
                $smsMessage .= "\n\n- PCEA Church";
                $smsService->sendSms($recipient->telephone, $smsMessage);
            }
        } catch (\Exception $e) {
            \Log::warning('Failed to send SMS for youth leader message', ['error' => $e->getMessage()]);
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
}

