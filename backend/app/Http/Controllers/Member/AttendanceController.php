<?php

namespace App\Http\Controllers\Member;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class AttendanceController extends Controller
{
    /**
     * Get authenticated member's attendance history
     */
    public function history(Request $request)
    {
        try {
            $user = $request->user();
            
            // Ensure user has a linked member profile
            $member = $user->member;
            
            // Fallback: Try to find member by email if relationship is not loaded or fails
            if (!$member) {
                $member = \App\Models\Member::where('email', $user->email)->first();
            }

            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member profile not found for this user. Please ensure your account email matches your member profile email.',
                    'data' => []
                ], 404);
            }

            $perPage = $request->input('per_page', 20);
            $startDate = $request->input('start_date');
            $endDate = $request->input('end_date');
            $eventType = $request->input('event_type');

            $query = Attendance::where('member_id', $member->id);

            // Date filtering
            if ($startDate && $endDate) {
                $query->whereBetween('event_date', [$startDate, $endDate]);
            }

            // Event Type filtering
            if ($eventType) {
                if ($eventType === 'Other') {
                    // "Other" means anything NOT in the standard list
                    $standardTypes = ['Sunday Service', 'Holy Communion', 'Weekly Meeting', 'AGM'];
                    $query->whereNotIn('event_type', $standardTypes);
                } else {
                    // Standard exact match (e.g., "Sunday Service")
                    $query->where('event_type', $eventType);
                }
            }

            $attendance = $query->orderBy('event_date', 'desc')
                ->orderBy('scanned_at', 'desc')
                ->paginate($perPage);

            return response()->json([
                'status' => 200,
                'message' => 'Attendance history retrieved successfully',
                'data' => $attendance
            ]);

        } catch (\Exception $e) {
            Log::error('Member attendance history error: ' . $e->getMessage());
            
            return response()->json([
                'status' => 500,
                'message' => 'Failed to retrieve attendance history',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
