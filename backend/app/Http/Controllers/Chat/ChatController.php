<?php

namespace App\Http\Controllers\Chat;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Member;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ChatController extends Controller
{
    /**
     * Get all conversations for the authenticated user
     */
    public function getConversations(Request $request)
    {
        $user = Auth::user();
        
        $conversations = Conversation::involving($user->id)
            ->with([
                'member:id,full_name,profile_image',
                'elder:id,full_name,profile_image',
                'latestMessage'
            ])
            ->orderBy('last_message_at', 'desc')
            ->get()
            ->map(function ($conversation) use ($user) {
                // Get the other participant
                $otherParticipant = $conversation->member_id == $user->id 
                    ? $conversation->elder 
                    : $conversation->member;
                    
                return [
                    'id' => $conversation->id,
                    'subject' => $conversation->subject,
                    'status' => $conversation->status,
                    'last_message_at' => $conversation->last_message_at,
                    'unread_count' => $conversation->unreadMessagesCount($user->id),
                    'other_participant' => [
                        'id' => $otherParticipant->id,
                        'name' => $otherParticipant->full_name,
                        'profile_image' => $otherParticipant->profile_image,
                        'is_online' => \App\Models\ChatOnlineStatus::isOnline($otherParticipant->id),
                    ],
                    'latest_message' => $conversation->latestMessage ? [
                        'id' => $conversation->latestMessage->id,
                        'message' => $conversation->latestMessage->message,
                        'sender_id' => $conversation->latestMessage->sender_id,
                        'sender_type' => $conversation->latestMessage->sender_type,
                        'created_at' => $conversation->latestMessage->created_at,
                        'is_read' => $conversation->latestMessage->is_read,
                    ] : null,
                ];
            });
            
        return response()->json([
            'status' => 200,
            'conversations' => $conversations
        ]);
    }

    /**
     * Get messages for a specific conversation
     */
    public function getMessages(Request $request, $conversationId)
    {
        $user = Auth::user();
        
        $conversation = Conversation::involving($user->id)
            ->findOrFail($conversationId);
            
        $messages = $conversation->messages()
            ->with('sender:id,full_name,profile_image')
            ->paginate(50);
            
        // Mark messages as read
        $conversation->markAsRead($user->id);
        
        return response()->json([
            'status' => 200,
            'messages' => $messages,
            'conversation' => [
                'id' => $conversation->id,
                'subject' => $conversation->subject,
                'status' => $conversation->status,
                'other_participant' => $conversation->member_id == $user->id 
                    ? $conversation->elder 
                    : $conversation->member,
            ]
        ]);
    }

    /**
     * Send a message
     */
    public function sendMessage(Request $request)
    {
        $user = Auth::user();
        
        $validated = $request->validate([
            'conversation_id' => 'required|exists:conversations,id',
            'message' => 'required|string|max:1000',
            'message_type' => 'sometimes|in:text,image,file',
            'attachment_url' => 'nullable|string',
            'attachment_name' => 'nullable|string',
        ]);

        $conversation = Conversation::involving($user->id)
            ->findOrFail($validated['conversation_id']);
            
        // Determine sender type based on user's role
        $senderType = $user->hasRole('elder') ? 'elder' : 'member';
        
        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $user->id,
            'sender_type' => $senderType,
            'message' => $validated['message'],
            'message_type' => $validated['message_type'] ?? 'text',
            'attachment_url' => $validated['attachment_url'] ?? null,
            'attachment_name' => $validated['attachment_name'] ?? null,
        ]);
        
        // Update conversation's last message time
        $conversation->update(['last_message_at' => now()]);
        
        // Load sender information
        $message->load('sender:id,full_name,profile_image');
        
        // Broadcast the message (for real-time updates)
        broadcast(new \App\Events\MessageSent($message, $conversation));
        
        return response()->json([
            'status' => 200,
            'message' => $message,
            'conversation_id' => $conversation->id
        ], 201);
    }

    /**
     * Start a new conversation
     */
    public function startConversation(Request $request)
    {
        $user = Auth::user();
        
        $validated = $request->validate([
            'member_id' => 'required|exists:members,id',
            'subject' => 'nullable|string|max:255',
            'initial_message' => 'required|string|max:1000',
        ]);

        $memberId = $validated['member_id'];
        
        // Check if conversation already exists
        $existingConversation = Conversation::where(function($query) use ($user, $memberId) {
            $query->where('member_id', $user->id)->where('elder_id', $memberId)
                  ->orWhere('member_id', $memberId)->where('elder_id', $user->id);
        })->first();
        
        if ($existingConversation) {
            return response()->json([
                'status' => 400,
                'message' => 'Conversation already exists',
                'conversation_id' => $existingConversation->id
            ]);
        }
        
        // Create new conversation
        $conversation = Conversation::create([
            'member_id' => $user->hasRole('elder') ? $memberId : $user->id,
            'elder_id' => $user->hasRole('elder') ? $user->id : $memberId,
            'subject' => $validated['subject'],
            'status' => 'active',
            'last_message_at' => now(),
        ]);
        
        // Send initial message
        $senderType = $user->hasRole('elder') ? 'elder' : 'member';
        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $user->id,
            'sender_type' => $senderType,
            'message' => $validated['initial_message'],
            'message_type' => 'text',
        ]);
        
        // Load relationships
        $conversation->load([
            'member:id,full_name,profile_image',
            'elder:id,full_name,profile_image'
        ]);
        $message->load('sender:id,full_name,profile_image');
        
        // Broadcast the new conversation and message
        broadcast(new \App\Events\ConversationStarted($conversation, $message));
        
        return response()->json([
            'status' => 200,
            'message' => 'Conversation started successfully',
            'conversation' => $conversation,
            'initial_message' => $message
        ], 201);
    }

    /**
     * Get available elders for members to chat with
     */
    public function getAvailableElders(Request $request)
    {
        $user = Auth::user();
        
        // Only members can get available elders
        if (!$user->hasRole('elder')) {
            $elders = Member::whereHas('roles', function($query) {
                $query->where('slug', 'elder');
            })
            ->where('is_active', true)
            ->select('id', 'full_name', 'profile_image', 'congregation')
            ->get()
            ->map(function($elder) {
                return [
                    'id' => $elder->id,
                    'name' => $elder->full_name,
                    'profile_image' => $elder->profile_image,
                    'congregation' => $elder->congregation,
                    'is_online' => \App\Models\ChatOnlineStatus::isOnline($elder->id),
                ];
            });
            
            return response()->json([
                'status' => 200,
                'elders' => $elders
            ]);
        }
        
        return response()->json([
            'status' => 403,
            'message' => 'Access denied'
        ], 403);
    }

    /**
     * Get members for elders to chat with
     */
    public function getMembers(Request $request)
    {
        $user = Auth::user();
        
        // Only elders can get members
        if ($user->hasRole('elder')) {
            $members = Member::where('is_active', true)
                ->select('id', 'full_name', 'profile_image', 'congregation')
                ->get()
                ->map(function($member) {
                    return [
                        'id' => $member->id,
                        'name' => $member->full_name,
                        'profile_image' => $member->profile_image,
                        'congregation' => $member->congregation,
                        'is_online' => \App\Models\ChatOnlineStatus::isOnline($member->id),
                    ];
                });
                
            return response()->json([
                'status' => 200,
                'members' => $members
            ]);
        }
        
        return response()->json([
            'status' => 403,
            'message' => 'Access denied'
        ], 403);
    }
}

