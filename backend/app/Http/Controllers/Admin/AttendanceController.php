<?php

namespace App\Http\Controllers\Admin;

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

                // Store attendance record
                $attendanceRecords[] = [
                    'member_id' => $member->id,
                    'e_kanisa_number' => $member->e_kanisa_number,
                    'full_name' => $member->full_name,
                    'congregation' => $member->congregation,
                    'event_type' => $eventType,
                    'event_date' => $eventDate,
                    'scanned_at' => now(),
                ];

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

            // Log attendance (you can replace this with database storage)
            Log::info('Attendance marked', [
                'user_id' => $user?->id,
                'count' => count($attendanceRecords),
                'records' => $attendanceRecords,
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

            // Send SMS confirmation
            $smsSent = false;
            if ($phoneNumber) {
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
            }

            // Log attendance
            Log::info('Single attendance marked', [
                'member_id' => $member->id,
                'e_kanisa_number' => $member->e_kanisa_number,
                'sms_sent' => $smsSent,
            ]);

            return response()->json([
                'status' => 200,
                'message' => 'Attendance marked successfully',
                'data' => [
                    'member_id' => $member->id,
                    'full_name' => $member->full_name,
                    'e_kanisa_number' => $member->e_kanisa_number,
                    'sms_sent' => $smsSent,
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
            $eventDate = $request->input('event_date', now()->toDateString());
            $eventType = $request->input('event_type');

            // This is a placeholder - implement based on your attendance storage
            return response()->json([
                'status' => 200,
                'message' => 'Attendance records retrieved',
                'data' => [],
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
     * Generate SMS message for attendance confirmation
     */
    protected function generateAttendanceSmsMessage(Member $member, string $eventType, string $eventDate): string
    {
        $date = date('l, F j, Y', strtotime($eventDate));
        $time = date('g:i A');
        
        $message = "ATTENDANCE CONFIRMED\n\n";
        $message .= "Dear {$member->full_name},\n\n";
        $message .= "Your attendance has been successfully marked for:\n";
        $message .= "Event: {$eventType}\n";
        $message .= "Date: {$date}\n";
        $message .= "Time: {$time}\n\n";
        
        if ($member->congregation) {
            $message .= "Congregation: {$member->congregation}\n";
        }
        
        $message .= "\nThank you for your presence. May God bless you!\n\n";
        $message .= "PCEA Church";
        
        return $message;
    }
}

