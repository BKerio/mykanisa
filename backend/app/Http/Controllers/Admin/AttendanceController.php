<?php

namespace App\Http\Controllers\Admin;

use App\Models\Attendance;
use App\Http\Controllers\Controller;
use App\Models\Member;
use App\Services\SmsService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class AttendanceController extends Controller
{
    /**
     * Mark attendance from QR code scan
     */
    public function markAttendance(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'members' => 'required|array|min:1',
            'members.*.member_id' => 'required|integer|exists:members,id',
            'members.*.e_kanisa_number' => 'required|string',
            'members.*.full_name' => 'required|string',
            'event_type' => 'nullable|string',
            'event_date' => 'nullable|date',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 400,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 400);
        }

        try {
            $user = $request->user();
            $members = $request->input('members', []);
            $eventType = $request->input('event_type', 'General Attendance');
            $eventDate = $request->input('event_date', now()->toDateString());
            $notes = $request->input('notes');

            // Get user's congregation if available
            $congregation = null;
            if ($user) {
                $userMember = Member::where('email', $user->email)->first();
                $congregation = $userMember?->congregation;
            }

            // Store attendance records and send SMS
            $attendanceRecords = [];
            $smsService = new SmsService();
            $smsResults = [];
            
            foreach ($members as $memberData) {
                $member = Member::find($memberData['member_id']);
                
                if (!$member) {
                    continue;
                }

                // Store attendance record - Check for duplicates first
                $attendance = Attendance::firstOrCreate(
                    [
                        'member_id' => $member->id,
                        'event_date' => $eventDate,
                        'event_type' => $eventType,
                    ],
                    [
                        'e_kanisa_number' => $member->e_kanisa_number,
                        'full_name' => $member->full_name,
                        'congregation' => $member->congregation,
                        'scanned_at' => now(),
                    ]
                );

                // Only add to result list if it was recently created or we want to show it regardless
                $attendanceRecords[] = $attendance;

                // Send SMS confirmation to member
                $phoneNumber = $memberData['phone'] ?? $member->telephone;
                if ($phoneNumber) {
                    $smsMessage = $this->generateAttendanceSmsMessage($member, $eventType, $eventDate);
                    $smsSent = $smsService->sendSms($phoneNumber, $smsMessage);
                    
                    $smsResults[] = [
                        'member_id' => $member->id,
                        'full_name' => $member->full_name,
                        'phone' => $phoneNumber,
                        'sms_sent' => $smsSent,
                    ];

                    if ($smsSent) {
                        Log::info('Attendance SMS sent successfully', [
                            'member_id' => $member->id,
                            'phone' => $phoneNumber,
                        ]);
                    } else {
                        Log::warning('Failed to send attendance SMS', [
                            'member_id' => $member->id,
                            'phone' => $phoneNumber,
                        ]);
                    }
                } else {
                    Log::warning('No phone number available for SMS', [
                        'member_id' => $member->id,
                        'full_name' => $member->full_name,
                    ]);
                }
            }

            // Log attendance
            Log::info('Attendance marked and saved', [
                'user_id' => $user?->id,
                'count' => count($attendanceRecords),
                'sms_results' => $smsResults,
            ]);

            $smsSentCount = count(array_filter($smsResults, fn($r) => $r['sms_sent']));
            
            return response()->json([
                'status' => 200,
                'message' => 'Attendance marked successfully',
                'data' => [
                    'count' => count($attendanceRecords),
                    'members' => $attendanceRecords,
                    'event_type' => $eventType,
                    'event_date' => $eventDate,
                    'sms_sent' => $smsSentCount,
                    'sms_total' => count($smsResults),
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Attendance marking error: ' . $e->getMessage());
            
            return response()->json([
                'status' => 500,
                'message' => 'Failed to mark attendance',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Mark single member attendance and send SMS immediately
     */
    public function markSingleAttendance(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'member_id' => 'required|integer|exists:members,id',
            'e_kanisa_number' => 'required|string',
            'full_name' => 'required|string',
            'phone' => 'nullable|string',
            'event_type' => 'nullable|string',
            'event_date' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 400,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 400);
        }

        try {
            $member = Member::find($request->member_id);
            
            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member not found',
                ], 404);
            }

            $eventType = $request->input('event_type', 'Digital Attendance');
            $eventDate = $request->input('event_date', now()->toDateString());
            $phoneNumber = $request->input('phone') ?: $member->telephone;

            // Save attendance record - Check for duplicates
            // We use firstOrCreate to ensure we never duplicate the record
            $attendance = Attendance::firstOrCreate(
                [
                    'member_id' => $member->id,
                    'event_date' => $eventDate,
                    'event_type' => $eventType,
                ],
                [
                    'e_kanisa_number' => $member->e_kanisa_number,
                    'full_name' => $member->full_name,
                    'congregation' => $member->congregation,
                    'scanned_at' => now(),
                ]
            );
            
            $wasRecentlyCreated = $attendance->wasRecentlyCreated;
            $smsSent = false;

            // Only send SMS if the attendance record is NEW
            if ($wasRecentlyCreated && $phoneNumber) {
                $smsService = new SmsService();
                $smsMessage = $this->generateAttendanceSmsMessage($member, $eventType, $eventDate);
                $smsSent = $smsService->sendSms($phoneNumber, $smsMessage);
                
                if ($smsSent) {
                    Log::info('Single attendance SMS sent', [
                        'member_id' => $member->id,
                        'phone' => $phoneNumber,
                    ]);
                } else {
                    Log::warning('Failed to send single attendance SMS', [
                        'member_id' => $member->id,
                        'phone' => $phoneNumber,
                    ]);
                }
            } else if (!$wasRecentlyCreated) {
                 Log::info('Duplicate attendance scan skipped SMS', [
                    'member_id' => $member->id,
                    'event_type' => $eventType
                ]);
            }

            // Log attendance result
            Log::info('Single attendance marked', [
                'member_id' => $member->id,
                'attendance_id' => $attendance->id,
                'is_new' => $wasRecentlyCreated,
                'sms_sent' => $smsSent,
            ]);

            return response()->json([
                'status' => 200,
                'message' => $wasRecentlyCreated ? 'Attendance marked successfully' : 'Member already marked for this event',
                'data' => [
                    'member_id' => $member->id,
                    'full_name' => $member->full_name,
                    'e_kanisa_number' => $member->e_kanisa_number,
                    'sms_sent' => $smsSent,
                    'was_recently_created' => $wasRecentlyCreated,
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Single attendance marking error: ' . $e->getMessage());
            
            return response()->json([
                'status' => 500,
                'message' => 'Failed to mark attendance',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get attendance records
     */
    public function getAttendance(Request $request)
    {
        try {
            $startDate = $request->input('start_date');
            $endDate = $request->input('end_date');
            $eventType = $request->input('event_type');

            $query = Attendance::query();

            if ($startDate) {
                $query->whereDate('event_date', '>=', $startDate);
            }

            if ($endDate) {
                $query->whereDate('event_date', '<=', $endDate);
            }
            
            // If no date range provided, default to today? Or show all?
            // Let's default to today if no filters at all, for performance, unless specific flag
            if (!$startDate && !$endDate && !$eventType) {
                 $query->whereDate('event_date', now()->toDateString());
            }

            $records = $query->when($eventType, function($q) use ($eventType) {
                    return $q->where('event_type', $eventType);
                })
                ->orderBy('scanned_at', 'desc')
                ->get();

            return response()->json([
                'status' => 200,
                'message' => 'Attendance records retrieved',
                'data' => $records,
            ]);

        } catch (\Exception $e) {
            Log::error('Get attendance error: ' . $e->getMessage());
            
            return response()->json([
                'status' => 500,
                'message' => 'Failed to retrieve attendance',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Generate SMS message for attendance confirmation based on occasion
     */
    protected function generateAttendanceSmsMessage(Member $member, string $eventType, string $eventDate): string
    {
        $date = date('l, F j, Y', strtotime($eventDate));
        $time = date('g:i A');
        $eventTypeLower = strtolower(trim($eventType));
        
        // Customize message based on occasion type
        if (strpos($eventTypeLower, 'holy communion') !== false) {
            // Holy Communion message
            $message = "HOLY COMMUNION ATTENDANCE\n\n";
            $message .= "Dear {$member->full_name},\n\n";
            $message .= "Your attendance for Holy Communion has been confirmed.\n\n";
            $message .= "Date: {$date}\n";
            $message .= "Time: {$time}\n\n";
            
            if ($member->congregation) {
                $message .= "Congregation: {$member->congregation}\n\n";
            }
            
            $message .= "Thank you for participating in this sacred sacrament. May the body and blood of our Lord Jesus Christ strengthen your faith.\n\n";
            $message .= "God bless you!\n\n";
            $message .= "PCEA Church";
            
        } elseif (strpos($eventTypeLower, 'sunday service') !== false) {
            // Sunday Service message
            $message = "SUNDAY SERVICE ATTENDANCE\n\n";
            $message .= "Dear {$member->full_name},\n\n";
            $message .= "Your attendance for Sunday Service has been confirmed.\n\n";
            $message .= "Date: {$date}\n";
            $message .= "Time: {$time}\n\n";
            
            if ($member->congregation) {
                $message .= "Congregation: {$member->congregation}\n\n";
            }
            
            $message .= "Thank you for joining us in worship. May God's word enrich your life this week.\n\n";
            $message .= "Blessings!\n\n";
            $message .= "PCEA Church";
            
        } elseif (strpos($eventTypeLower, 'weekly meeting') !== false) {
            // Weekly Meeting message
            $message = "WEEKLY MEETING ATTENDANCE\n\n";
            $message .= "Dear {$member->full_name},\n\n";
            $message .= "Your attendance for Weekly Meeting has been confirmed.\n\n";
            $message .= "Date: {$date}\n";
            $message .= "Time: {$time}\n\n";
            
            if ($member->congregation) {
                $message .= "Congregation: {$member->congregation}\n\n";
            }
            
            $message .= "Thank you for your participation. Your presence strengthens our church community.\n\n";
            $message .= "God bless you!\n\n";
            $message .= "PCEA Church";
            
        } elseif (strpos($eventTypeLower, 'annual general meeting') !== false || strpos($eventTypeLower, 'agm') !== false) {
            // Annual General Meeting message
            $message = "ANNUAL GENERAL MEETING\n\n";
            $message .= "Dear {$member->full_name},\n\n";
            $message .= "Your attendance for the Annual General Meeting has been confirmed.\n\n";
            $message .= "Date: {$date}\n";
            $message .= "Time: {$time}\n\n";
            
            if ($member->congregation) {
                $message .= "Congregation: {$member->congregation}\n\n";
            }
            
            $message .= "Thank you for your participation in our AGM. Your voice matters in shaping our church's future.\n\n";
            $message .= "God bless you!\n\n";
            $message .= "PCEA Church";
            
        } else {
            // Default message for custom occasions
            $message = "ATTENDANCE CONFIRMED\n\n";
            $message .= "Dear {$member->full_name},\n\n";
            $message .= "Your attendance has been successfully marked for:\n";
            $message .= "Event: {$eventType}\n";
            $message .= "Date: {$date}\n";
            $message .= "Time: {$time}\n\n";
            
            if ($member->congregation) {
                $message .= "Congregation: {$member->congregation}\n\n";
            }
            
            $message .= "Thank you for your presence. May God bless you!\n\n";
            $message .= "PCEA Church";
        }
        
        return $message;
    }
}

