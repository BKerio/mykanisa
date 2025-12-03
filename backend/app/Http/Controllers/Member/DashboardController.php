<?php

namespace App\Http\Controllers\Member;

use App\Http\Controllers\Controller;
use App\Models\Contribution;
use App\Models\Dependency;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class DashboardController extends Controller
{
    /**
     * Get member dashboard data
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        // Get member's basic info
        $member = $user->load(['dependencies', 'groups', 'roles']);
        
        // Get contribution statistics
        $totalContributions = Contribution::where('member_id', $user->id)->sum('amount');
        $contributionsCount = Contribution::where('member_id', $user->id)->count();
        $thisMonthContributions = Contribution::where('member_id', $user->id)
            ->whereMonth('contribution_date', now()->month)
            ->whereYear('contribution_date', now()->year)
            ->sum('amount');
            
        // Get payment statistics
        $totalPayments = Payment::where('member_id', $user->id)->sum('amount');
        $paymentsCount = Payment::where('member_id', $user->id)->count();
        $thisMonthPayments = Payment::where('member_id', $user->id)
            ->whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)
            ->sum('amount');
            
        // Get dependents count
        $dependentsCount = Dependency::where('member_id', $user->id)->count();
        
        // Get recent contributions (last 5)
        $recentContributions = Contribution::where('member_id', $user->id)
            ->orderBy('contribution_date', 'desc')
            ->limit(5)
            ->get();
            
        // Get recent payments (last 5)
        $recentPayments = Payment::where('member_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();
            
        // Get monthly contribution trend (last 6 months)
        $monthlyTrend = Contribution::where('member_id', $user->id)
            ->where('contribution_date', '>=', now()->subMonths(6))
            ->selectRaw('DATE_FORMAT(contribution_date, "%Y-%m") as month, SUM(amount) as total')
            ->groupBy('month')
            ->orderBy('month')
            ->get()
            ->keyBy('month');
            
        // Get contribution types breakdown
        $contributionTypes = Contribution::where('member_id', $user->id)
            ->selectRaw('type, SUM(amount) as total, COUNT(*) as count')
            ->groupBy('type')
            ->get();
            
        return response()->json([
            'status' => 200,
            'dashboard' => [
                'member' => $member,
                'statistics' => [
                    'contributions' => [
                        'total_amount' => $totalContributions,
                        'total_count' => $contributionsCount,
                        'this_month' => $thisMonthContributions,
                    ],
                    'payments' => [
                        'total_amount' => $totalPayments,
                        'total_count' => $paymentsCount,
                        'this_month' => $thisMonthPayments,
                    ],
                    'dependents_count' => $dependentsCount,
                ],
                'recent_activity' => [
                    'contributions' => $recentContributions,
                    'payments' => $recentPayments,
                ],
                'trends' => [
                    'monthly_contributions' => $monthlyTrend,
                    'contribution_types' => $contributionTypes,
                ]
            ]
        ]);
    }

    /**
     * Get member's notifications/alerts and messages from elders
     */
    public function notifications(Request $request)
    {
        $user = $request->user();
        
        // Get member ID - handle both Member and User instances
        $memberId = null;
        $member = null;
        $congregation = null;
        
        if ($user instanceof \App\Models\Member) {
            $memberId = $user->id;
            $member = $user;
            $congregation = $user->congregation ?? null;
        } else {
            // User is from users table, find corresponding Member
            $member = \App\Models\Member::where('email', $user->email)->first();
            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member record not found'
                ], 404);
            }
            $memberId = $member->id;
            $congregation = $member->congregation ?? null;
        }
        
        // Get all announcements visible to this member
        // Broadcast announcements are visible to all members
        // Individual announcements are visible only to the recipient
        // Exclude announcements deleted by this member
        $announcements = \App\Models\Announcement::where(function($query) use ($memberId) {
                $query->where('type', 'broadcast')
                    ->orWhere(function($q) use ($memberId) {
                        $q->where('type', 'individual')
                          ->where('recipient_id', $memberId);
                    });
            })
            ->where(function($query) use ($memberId) {
                // Exclude announcements deleted by this member
                $query->whereNull('deleted_by_member_id')
                      ->orWhere('deleted_by_member_id', '!=', $memberId);
            })
            ->with(['sender' => function($query) {
                $query->select('id', 'full_name', 'email', 'role');
            }, 'replies.sender' => function($query) {
                $query->select('id', 'full_name', 'email', 'role');
            }, 'readers' => function($query) use ($memberId) {
                $query->where('member_id', $memberId)->select('member_id', 'read_at');
            }])
            ->orderBy('is_priority', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        // Add read status to each announcement
        $notificationsData = $announcements->map(function($announcement) use ($memberId) {
            $announcementArray = $announcement->toArray();
            $announcementArray['is_read'] = $announcement->isReadBy($memberId);
            $announcementArray['read_at'] = $announcement->readers()
                ->where('member_id', $memberId)
                ->first()?->pivot->read_at;
            return $announcementArray;
        });

        // Count unread messages
        $unreadCount = \App\Models\Announcement::where(function($query) use ($memberId) {
                $query->where('type', 'broadcast')
                    ->orWhere(function($q) use ($memberId) {
                        $q->where('type', 'individual')
                          ->where('recipient_id', $memberId);
                    });
            })
            ->where(function($query) use ($memberId) {
                $query->whereNull('deleted_by_member_id')
                      ->orWhere('deleted_by_member_id', '!=', $memberId);
            })
            ->whereDoesntHave('readers', function($q) use ($memberId) {
                $q->where('member_id', $memberId);
            })
            ->count();

        return response()->json([
            'status' => 200,
            'notifications' => $notificationsData,
            'unread_count' => $unreadCount,
            'pagination' => [
                'current_page' => $announcements->currentPage(),
                'last_page' => $announcements->lastPage(),
                'per_page' => $announcements->perPage(),
                'total' => $announcements->total(),
            ],
            'congregation' => $congregation,
        ]);
    }

    /**
     * Reply to an announcement
     */
    public function reply(Request $request, $announcementId)
    {
        $user = $request->user();
        
        // Get member ID
        $memberId = null;
        if ($user instanceof \App\Models\Member) {
            $memberId = $user->id;
        } else {
            $member = \App\Models\Member::where('email', $user->email)->first();
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

        // Find the original announcement
        $originalAnnouncement = \App\Models\Announcement::findOrFail($announcementId);
        
        // Check if member can reply to this announcement
        // Member can reply if:
        // 1. It's a broadcast message (visible to all)
        // 2. It's an individual message sent to them
        // 3. It hasn't been deleted by them
        $canReply = false;
        if ($originalAnnouncement->type === 'broadcast') {
            $canReply = true;
        } elseif ($originalAnnouncement->type === 'individual' && 
                  $originalAnnouncement->recipient_id == $memberId) {
            $canReply = true;
        }

        if (!$canReply || $originalAnnouncement->isDeletedByMember($memberId)) {
            return response()->json([
                'status' => 403,
                'message' => 'You cannot reply to this message'
            ], 403);
        }

        // Get the sender (elder) of the original message
        $elderId = $originalAnnouncement->sent_by;

        // Create reply as a new announcement
        $reply = \App\Models\Announcement::create([
            'title' => 'Re: ' . $originalAnnouncement->title,
            'message' => $validated['message'],
            'type' => 'individual',
            'sent_by' => $memberId, // Member is replying
            'recipient_id' => $elderId, // Reply goes to the elder who sent the original
            'reply_to' => $announcementId,
            'is_priority' => false,
        ]);

        // Send SMS to elder if they have a phone number
        try {
            $elder = \App\Models\Member::find($elderId);
            $memberName = $member->full_name ?? ($user instanceof \App\Models\Member ? $user->full_name : 'Member');
            if ($elder && $elder->telephone) {
                $smsService = app(\App\Services\SmsService::class);
                $smsMessage = "Hello {$elder->full_name},\n\n";
                $smsMessage .= "Reply from {$memberName}:\n\n";
                $smsMessage .= "Re: {$originalAnnouncement->title}\n\n";
                $smsMessage .= $validated['message'];
                $smsMessage .= "\n\n- PCEA Church";
                $smsService->sendSms($elder->telephone, $smsMessage);
            }
        } catch (\Exception $e) {
            \Log::warning('Failed to send SMS for reply', ['error' => $e->getMessage()]);
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
     * Delete an announcement for a member (soft delete)
     */
    public function delete(Request $request, $announcementId)
    {
        $user = $request->user();
        
        // Get member ID
        $memberId = null;
        if ($user instanceof \App\Models\Member) {
            $memberId = $user->id;
        } else {
            $member = \App\Models\Member::where('email', $user->email)->first();
            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member record not found'
                ], 404);
            }
            $memberId = $member->id;
        }

        // Find the announcement
        $announcement = \App\Models\Announcement::findOrFail($announcementId);
        
        // Check if member can delete this announcement
        // Member can delete if:
        // 1. It's a broadcast message (visible to all)
        // 2. It's an individual message sent to them
        $canDelete = false;
        if ($announcement->type === 'broadcast') {
            $canDelete = true;
        } elseif ($announcement->type === 'individual' && 
                  $announcement->recipient_id == $memberId) {
            $canDelete = true;
        }

        if (!$canDelete) {
            return response()->json([
                'status' => 403,
                'message' => 'You cannot delete this message'
            ], 403);
        }

        // Mark as deleted by this member
        $announcement->markAsDeletedByMember($memberId);

        return response()->json([
            'status' => 200,
            'message' => 'Message deleted successfully',
        ]);
    }

    /**
     * Send a new message to an elder
     */
    public function sendMessageToElder(Request $request)
    {
        $user = $request->user();
        
        // Get member ID
        $memberId = null;
        $member = null;
        if ($user instanceof \App\Models\Member) {
            $memberId = $user->id;
            $member = $user;
        } else {
            $member = \App\Models\Member::where('email', $user->email)->first();
            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member record not found'
                ], 404);
            }
            $memberId = $member->id;
        }

        $validated = $request->validate([
            'elder_id' => 'required|exists:members,id',
            'title' => 'required|string|max:255',
            'message' => 'required|string|max:5000',
        ]);

        // Verify the recipient is an elder
        $elder = \App\Models\Member::findOrFail($validated['elder_id']);
        $elderRole = strtolower(trim($elder->role ?? 'member'));
        if ($elderRole !== 'elder') {
            return response()->json([
                'status' => 403,
                'message' => 'The recipient must be an elder'
            ], 403);
        }

        // Create the message
        $announcement = \App\Models\Announcement::create([
            'title' => $validated['title'],
            'message' => $validated['message'],
            'type' => 'individual',
            'sent_by' => $memberId, // Member is sending
            'recipient_id' => $validated['elder_id'], // Elder is receiving
            'is_priority' => false,
        ]);

        // Send SMS to elder if they have a phone number
        try {
            if ($elder->telephone) {
                $smsService = app(\App\Services\SmsService::class);
                $memberName = $member->full_name ?? 'Member';
                $smsMessage = "Hello {$elder->full_name},\n\n";
                $smsMessage .= "Message from {$memberName}:\n\n";
                $smsMessage .= "Subject: {$validated['title']}\n\n";
                $smsMessage .= $validated['message'];
                $smsMessage .= "\n\n- PCEA Church";
                $smsService->sendSms($elder->telephone, $smsMessage);
            }
        } catch (\Exception $e) {
            \Log::warning('Failed to send SMS for member message', ['error' => $e->getMessage()]);
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
            'message' => 'Message sent to elder successfully',
            'announcement' => $announcement,
        ], 201);
    }

    /**
     * Get list of elders (for member to select when sending message)
     */
    public function getElders(Request $request)
    {
        $elders = \App\Models\Member::where('role', 'elder')
            ->where('is_active', true)
            ->select('id', 'full_name', 'email', 'telephone', 'congregation', 'role')
            ->orderBy('full_name')
            ->get();

        return response()->json([
            'status' => 200,
            'elders' => $elders,
        ]);
    }

    /**
     * Get messages sent by member to elders
     */
    public function sentMessages(Request $request)
    {
        $user = $request->user();
        
        // Get member ID
        $memberId = null;
        if ($user instanceof \App\Models\Member) {
            $memberId = $user->id;
        } else {
            $member = \App\Models\Member::where('email', $user->email)->first();
            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member record not found'
                ], 404);
            }
            $memberId = $member->id;
        }
        
        // Get messages sent by this member to elders
        // Messages where member is the sender and recipient is an elder
        $messages = \App\Models\Announcement::where('sent_by', $memberId)
            ->whereHas('recipient', function($query) {
                $query->where('role', 'elder');
            })
            ->with(['recipient' => function($query) {
                $query->select('id', 'full_name', 'email', 'telephone', 'role');
            }, 'replies.sender' => function($query) {
                $query->select('id', 'full_name', 'email', 'role');
            }, 'readers' => function($query) use ($memberId) {
                $query->where('member_id', $memberId)->select('member_id', 'read_at');
            }])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        // Add read status (from elder's perspective - if elder has read the message)
        $messagesData = $messages->map(function($message) use ($memberId) {
            $messageArray = $message->toArray();
            // Check if the recipient (elder) has read this message
            if ($message->recipient_id) {
                $messageArray['is_read_by_recipient'] = $message->isReadBy($message->recipient_id);
                $messageArray['read_at_by_recipient'] = $message->readers()
                    ->where('member_id', $message->recipient_id)
                    ->first()?->pivot->read_at;
            }
            return $messageArray;
        });

        return response()->json([
            'status' => 200,
            'messages' => $messagesData,
            'pagination' => [
                'current_page' => $messages->currentPage(),
                'last_page' => $messages->lastPage(),
                'per_page' => $messages->perPage(),
                'total' => $messages->total(),
            ],
        ]);
    }

    /**
     * Mark an announcement as read
     */
    public function markAsRead(Request $request, $announcementId)
    {
        $user = $request->user();
        
        // Get member ID
        $memberId = null;
        if ($user instanceof \App\Models\Member) {
            $memberId = $user->id;
        } else {
            $member = \App\Models\Member::where('email', $user->email)->first();
            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member record not found'
                ], 404);
            }
            $memberId = $member->id;
        }
        
        $announcement = \App\Models\Announcement::findOrFail($announcementId);
        
        // Verify the member has access to this announcement
        $hasAccess = ($announcement->type === 'broadcast') ||
                     ($announcement->type === 'individual' && $announcement->recipient_id == $memberId);
        
        if (!$hasAccess) {
            return response()->json([
                'status' => 403,
                'message' => 'You do not have access to this message'
            ], 403);
        }
        
        // Mark as read
        if (!$announcement->isReadBy($memberId)) {
            $announcement->markAsReadBy($memberId);
        }
        
        // Get updated unread count
        $unreadCount = \App\Models\Announcement::where(function($query) use ($memberId) {
                $query->where('type', 'broadcast')
                    ->orWhere(function($q) use ($memberId) {
                        $q->where('type', 'individual')
                          ->where('recipient_id', $memberId);
                    });
            })
            ->where(function($query) use ($memberId) {
                $query->whereNull('deleted_by_member_id')
                      ->orWhere('deleted_by_member_id', '!=', $memberId);
            })
            ->whereDoesntHave('readers', function($q) use ($memberId) {
                $q->where('member_id', $memberId);
            })
            ->count();
        
        return response()->json([
            'status' => 200,
            'message' => 'Message marked as read',
            'unread_count' => $unreadCount,
        ]);
    }

    /**
     * Get unread message count
     */
    public function unreadCount(Request $request)
    {
        $user = $request->user();
        
        // Get member ID
        $memberId = null;
        if ($user instanceof \App\Models\Member) {
            $memberId = $user->id;
        } else {
            $member = \App\Models\Member::where('email', $user->email)->first();
            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member record not found'
                ], 404);
            }
            $memberId = $member->id;
        }
        
        $unreadCount = \App\Models\Announcement::where(function($query) use ($memberId) {
                $query->where('type', 'broadcast')
                    ->orWhere(function($q) use ($memberId) {
                        $q->where('type', 'individual')
                          ->where('recipient_id', $memberId);
                    });
            })
            ->where(function($query) use ($memberId) {
                $query->whereNull('deleted_by_member_id')
                      ->orWhere('deleted_by_member_id', '!=', $memberId);
            })
            ->whereDoesntHave('readers', function($q) use ($memberId) {
                $q->where('member_id', $memberId);
            })
            ->count();
        
        return response()->json([
            'status' => 200,
            'unread_count' => $unreadCount,
        ]);
    }

    /**
     * Get member's upcoming events
     */
    public function events(Request $request)
    {
        $user = $request->user();
        
        // This would typically come from an events table
        // For now, return some mock events
        $events = [
            [
                'id' => 1,
                'title' => 'Sunday Service',
                'date' => now()->nextSunday()->format('Y-m-d'),
                'time' => '10:00',
                'location' => 'Main Sanctuary',
                'type' => 'service',
            ],
            [
                'id' => 2,
                'title' => 'Bible Study',
                'date' => now()->nextWednesday()->format('Y-m-d'),
                'time' => '19:00',
                'location' => 'Church Library',
                'type' => 'study',
            ],
        ];
        
        return response()->json([
            'status' => 200,
            'events' => $events
        ]);
    }
}

