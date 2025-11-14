<?php

namespace App\Http\Controllers\Elder;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use App\Models\Member;
use App\Services\SmsService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class MessagesController extends Controller
{
    protected SmsService $smsService;

    public function __construct(SmsService $smsService)
    {
        $this->smsService = $smsService;
    }

    /**
     * Store a new announcement/message
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'type' => 'required|in:broadcast,individual,group',
            'is_priority' => 'sometimes|boolean',
            'recipient_id' => 'nullable|exists:members,id',
            'recipient_phone' => 'nullable|string',
        ]);

        $user = $request->user();
        
        // Ensure we have a Member instance with a valid ID
        $memberId = null;
        if ($user instanceof Member) {
            $memberId = $user->id;
        } else {
            // If user is from users table, find the corresponding member
            $member = Member::where('email', $user->email)->first();
            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member record not found for authenticated user'
                ], 404);
            }
            $memberId = $member->id;
        }
        
        $recipientId = null;
        $targetCount = 0;

        // Handle individual messages
        $recipient = null;
        if ($validated['type'] === 'individual') {
            if (!empty($validated['recipient_id'])) {
                $recipient = Member::find($validated['recipient_id']);
            } elseif (!empty($validated['recipient_phone'])) {
                // Find member by phone number
                $recipient = Member::where('telephone', $validated['recipient_phone'])
                    ->orWhere('telephone', 'like', '%' . preg_replace('/[^0-9]/', '', $validated['recipient_phone']) . '%')
                    ->first();
            }
            
            if (!$recipient) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Recipient not found. Please check the phone number or select a member from the list.'
                ], 404);
            }
            
            if (empty($recipient->telephone)) {
                return response()->json([
                    'status' => 400,
                    'message' => 'Recipient does not have a phone number registered.'
                ], 400);
            }
            
            $recipientId = $recipient->id;
            $targetCount = 1;
        } elseif ($validated['type'] === 'broadcast') {
            // Count all active members with phone numbers for broadcast
            $targetCount = Member::where('is_active', true)
                ->whereNotNull('telephone')
                ->where('telephone', '!=', '')
                ->count();
        }

        // Create the announcement first
        $announcement = Announcement::create([
            'title' => $validated['title'],
            'message' => $validated['message'],
            'type' => $validated['type'],
            'sent_by' => $memberId,
            'recipient_id' => $recipientId,
            'is_priority' => $validated['is_priority'] ?? false,
            'target_count' => $targetCount,
        ]);

        // Send SMS for individual and broadcast messages
        $smsSent = false;
        $smsError = null;
        $smsSentCount = 0;
        $smsFailedCount = 0;
        
        if ($validated['type'] === 'individual' && $recipient) {
            // Send SMS to individual recipient
            try {
                $smsMessage = "From PCEA Church\n\n";
                $smsMessage .= "Title: " . $validated['title'] . "\n\n";
                $smsMessage .= $validated['message'];
                
                $smsSent = $this->smsService->sendSms($recipient->telephone, $smsMessage);
                
                if (!$smsSent) {
                    $smsError = 'Message saved but SMS delivery failed';
                    Log::warning('Failed to send SMS for announcement', [
                        'announcement_id' => $announcement->id,
                        'recipient_id' => $recipient->id,
                        'phone' => $recipient->telephone,
                    ]);
                } else {
                    $smsSentCount = 1;
                    Log::info('SMS sent successfully for announcement', [
                        'announcement_id' => $announcement->id,
                        'recipient_id' => $recipient->id,
                        'phone' => $recipient->telephone,
                    ]);
                }
            } catch (\Exception $e) {
                $smsError = 'Message saved but SMS delivery failed: ' . $e->getMessage();
                Log::error('Error sending SMS for announcement', [
                    'announcement_id' => $announcement->id,
                    'recipient_id' => $recipient->id,
                    'error' => $e->getMessage(),
                ]);
            }
        } elseif ($validated['type'] === 'broadcast') {
            // Send SMS to all members with phone numbers
            $broadcastMembers = Member::where('is_active', true)
                ->whereNotNull('telephone')
                ->where('telephone', '!=', '')
                ->get();
            
            $smsMessage = "From PCEA Church\n\n";
            $smsMessage .= "Title: " . $validated['title'] . "\n\n";
            $smsMessage .= $validated['message'];
            
            foreach ($broadcastMembers as $member) {
                try {
                    $smsResult = $this->smsService->sendSms($member->telephone, $smsMessage);
                    if ($smsResult) {
                        $smsSentCount++;
                    } else {
                        $smsFailedCount++;
                        Log::warning('Failed to send broadcast SMS', [
                            'announcement_id' => $announcement->id,
                            'member_id' => $member->id,
                            'phone' => $member->telephone,
                        ]);
                    }
                } catch (\Exception $e) {
                    $smsFailedCount++;
                    Log::error('Error sending broadcast SMS', [
                        'announcement_id' => $announcement->id,
                        'member_id' => $member->id,
                        'phone' => $member->telephone,
                        'error' => $e->getMessage(),
                    ]);
                }
            }
            
            Log::info('Broadcast SMS completed', [
                'announcement_id' => $announcement->id,
                'total_targets' => $broadcastMembers->count(),
                'sms_sent' => $smsSentCount,
                'sms_failed' => $smsFailedCount,
            ]);
            
            $smsSent = $smsSentCount > 0;
            if ($smsFailedCount > 0 && $smsSentCount > 0) {
                $smsError = "Sent to {$smsSentCount} member(s). Failed to send to {$smsFailedCount} member(s).";
            } elseif ($smsFailedCount > 0) {
                $smsError = "Failed to send SMS to {$smsFailedCount} member(s).";
            }
        }

        return response()->json([
            'status' => 201,
            'message' => $validated['type'] === 'individual' 
                ? ($smsSent 
                    ? 'Announcement saved and SMS sent successfully' 
                    : ($smsError ?? 'Announcement saved successfully'))
                : ($smsSentCount > 0
                    ? "Announcement saved and sent to {$smsSentCount} member(s)." . 
                      ($smsFailedCount > 0 ? " Failed to send to {$smsFailedCount} member(s)." : "")
                    : ($smsError ?? 'Announcement saved successfully')),
            'announcement' => $announcement->load(['sender', 'recipient']),
            'target_count' => $targetCount,
            'sms_sent' => $smsSent,
            'sms_sent_count' => $smsSentCount,
            'sms_failed_count' => $smsFailedCount,
        ], 201);
    }

    /**
     * Get messages from members to this elder
     */
    public function messagesFromMembers(Request $request)
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

        // Get messages where elder is the recipient and sender is a member (not elder)
        $messages = Announcement::where('recipient_id', $memberId)
            ->whereHas('sender', function($query) {
                $query->where('role', '!=', 'elder')
                      ->orWhereNull('role');
            })
            ->with(['sender' => function($query) {
                $query->select('id', 'full_name', 'email', 'role', 'telephone');
            }, 'replies.sender' => function($query) {
                $query->select('id', 'full_name', 'email', 'role');
            }])
            ->orderBy('is_priority', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        // Mark unread messages
        foreach ($messages as $message) {
            if (!$message->isReadBy($memberId)) {
                $message->markAsReadBy($memberId);
            }
        }

        return response()->json([
            'status' => 200,
            'messages' => $messages->items(),
            'pagination' => [
                'current_page' => $messages->currentPage(),
                'last_page' => $messages->lastPage(),
                'per_page' => $messages->perPage(),
                'total' => $messages->total(),
            ],
        ]);
    }

    /**
     * Reply to a message from a member
     */
    public function replyToMember(Request $request, $announcementId)
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

        $validated = $request->validate([
            'message' => 'required|string|max:5000',
        ]);

        // Find the original message
        $originalMessage = Announcement::findOrFail($announcementId);
        
        // Verify this elder is the recipient
        if ($originalMessage->recipient_id != $memberId) {
            return response()->json([
                'status' => 403,
                'message' => 'You cannot reply to this message'
            ], 403);
        }

        // Get the sender (member) of the original message
        $memberSenderId = $originalMessage->sent_by;

        // Create reply
        $reply = Announcement::create([
            'title' => 'Re: ' . $originalMessage->title,
            'message' => $validated['message'],
            'type' => 'individual',
            'sent_by' => $memberId, // Elder is replying
            'recipient_id' => $memberSenderId, // Reply goes to the member
            'reply_to' => $announcementId,
            'is_priority' => false,
        ]);

        // Send SMS to member if they have a phone number
        try {
            $member = Member::find($memberSenderId);
            if ($member && $member->telephone) {
                $elderName = $user instanceof Member ? $user->full_name : 'Church Elder';
                $smsMessage = "Reply from {$elderName}\n\n";
                $smsMessage .= "Re: {$originalMessage->title}\n\n";
                $smsMessage .= $validated['message'];
                $this->smsService->sendSms($member->telephone, $smsMessage);
            }
        } catch (\Exception $e) {
            Log::warning('Failed to send SMS for elder reply', ['error' => $e->getMessage()]);
        }

        $reply->load(['sender' => function($query) {
            $query->select('id', 'full_name', 'email', 'role');
        }]);

        return response()->json([
            'status' => 200,
            'message' => 'Reply sent successfully',
            'reply' => $reply,
        ], 201);
    }

    /**
     * Get all announcements sent by the current elder
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
        
        $announcements = Announcement::where('sent_by', $memberId)
            ->with(['sender', 'recipient'])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'status' => 200,
            'announcements' => $announcements,
        ]);
    }

    /**
     * Get a specific announcement
     */
    public function show(Request $request, Announcement $announcement)
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
        
        // Only the sender can view their own announcements
        if ($announcement->sent_by !== $memberId) {
            return response()->json([
                'status' => 403,
                'message' => 'Unauthorized'
            ], 403);
        }

        $announcement->load(['sender', 'recipient', 'readers']);

        return response()->json([
            'status' => 200,
            'announcement' => $announcement,
        ]);
    }

    /**
     * Broadcast message (saves to DB and sends SMS to all members)
     */
    public function broadcast(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'congregation' => 'nullable|string',
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
        
        // Get target members
        $query = Member::where('is_active', true)
            ->whereNotNull('telephone')
            ->where('telephone', '!=', '');
        
        // Elder can target specific congregation if needed, but defaults to all
        if (!empty($validated['congregation'])) {
            $query->where('congregation', $validated['congregation']);
        }
        
        $targetMembers = $query->get();
        $targetCount = $targetMembers->count();

        // Create the announcement first
        $announcement = Announcement::create([
            'title' => $validated['title'],
            'message' => $validated['message'],
            'type' => 'broadcast',
            'sent_by' => $memberId,
            'is_priority' => false,
            'target_count' => $targetCount,
        ]);

        // Send SMS to all target members
        $smsSentCount = 0;
        $smsFailedCount = 0;
        $smsMessage = "From PCEA Church\n\n";
        $smsMessage .= "Title: " . $validated['title'] . "\n\n";
        $smsMessage .= $validated['message'];
        
        foreach ($targetMembers as $member) {
            try {
                $smsSent = $this->smsService->sendSms($member->telephone, $smsMessage);
                if ($smsSent) {
                    $smsSentCount++;
                } else {
                    $smsFailedCount++;
                    Log::warning('Failed to send broadcast SMS', [
                        'announcement_id' => $announcement->id,
                        'member_id' => $member->id,
                        'phone' => $member->telephone,
                    ]);
                }
            } catch (\Exception $e) {
                $smsFailedCount++;
                Log::error('Error sending broadcast SMS', [
                    'announcement_id' => $announcement->id,
                    'member_id' => $member->id,
                    'phone' => $member->telephone,
                    'error' => $e->getMessage(),
                ]);
            }
        }
        
        Log::info('Broadcast SMS completed', [
            'announcement_id' => $announcement->id,
            'total_targets' => $targetCount,
            'sms_sent' => $smsSentCount,
            'sms_failed' => $smsFailedCount,
        ]);

        return response()->json([
            'status' => 200,
            'message' => "Broadcast message saved and sent to {$smsSentCount} member(s). " . 
                        ($smsFailedCount > 0 ? "Failed to send to {$smsFailedCount} member(s)." : ""),
            'announcement' => $announcement->load('sender'),
            'target_count' => $targetCount,
            'sms_sent_count' => $smsSentCount,
            'sms_failed_count' => $smsFailedCount,
        ]);
    }
}

