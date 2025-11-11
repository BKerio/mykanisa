<?php

namespace App\Http\Controllers\YouthLeader;

use App\Http\Controllers\Controller;
use App\Models\Member;
use Illuminate\Http\Request;

class YouthController extends Controller
{
    /**
     * Get youth members (typically ages 18-35)
     */
    public function members(Request $request)
    {
        $user = $request->user();
        
        $query = Member::query();
        
        $congregation = $request->input('congregation');
        
        if ($congregation) {
            $query->where('congregation', $congregation);
        }
        
        // Filter by age range (18-35 years old)
        $query->whereRaw('TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) BETWEEN 18 AND 35');
        
        $members = $query->with(['groups'])
            ->orderBy('full_name')
            ->get();
            
        return response()->json([
            'status' => 200,
            'members' => $members
        ]);
    }

    /**
     * Add new youth member
     */
    public function addMember(Request $request)
    {
        $validated = $request->validate([
            'full_name' => 'required|string|max:255',
            'email' => 'required|email|unique:members,email',
            'national_id' => 'required|string|unique:members,national_id',
            'date_of_birth' => 'required|date',
            'gender' => 'required|in:male,female',
            'marital_status' => 'required|string',
            'telephone' => 'required|string',
            'congregation' => 'required|string',
            'parish' => 'required|string',
            'presbytery' => 'required|string',
        ]);

        // Verify age is within youth range
        $age = \Carbon\Carbon::parse($validated['date_of_birth'])->age;
        if ($age < 18 || $age > 35) {
            return response()->json([
                'status' => 400,
                'message' => 'Member age must be between 18 and 35 years for youth ministry'
            ]);
        }

        $validated['region'] = $request->input('region', 'Nairobi');
        $validated['is_active'] = true;
        
        $member = Member::create($validated);
        
        // Add to youth group
        $youthGroup = \App\Models\Group::firstOrCreate(
            ['name' => 'Youth'],
            ['description' => 'Youth Ministry Group']
        );
        $member->groups()->attach($youthGroup->id);
        
        return response()->json([
            'status' => 200,
            'message' => 'Youth member added successfully',
            'member' => $member->load('groups')
        ], 201);
    }

    /**
     * Get youth events/activities
     */
    public function events(Request $request)
    {
        $user = $request->user();
        
        // Mock data for youth events
        $events = [
            [
                'id' => 1,
                'title' => 'Youth Fellowship',
                'date' => now()->nextSunday()->format('Y-m-d'),
                'time' => '15:00',
                'description' => 'Weekly youth fellowship meeting',
                'location' => 'Youth Hall',
                'type' => 'fellowship',
                'attendance' => 25
            ],
            [
                'id' => 2,
                'title' => 'Bible Study',
                'date' => now()->nextWednesday()->format('Y-m-d'),
                'time' => '19:00',
                'description' => 'Youth bible study session',
                'location' => 'Church Library',
                'type' => 'study',
                'attendance' => 18
            ],
            [
                'id' => 3,
                'title' => 'Community Service',
                'date' => now()->nextSaturday()->format('Y-m-d'),
                'time' => '09:00',
                'description' => 'Community outreach program',
                'location' => 'Local Community Center',
                'type' => 'service',
                'attendance' => 12
            ]
        ];
        
        return response()->json([
            'status' => 200,
            'events' => $events
        ]);
    }

    /**
     * Create youth event
     */
    public function createEvent(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'date' => 'required|date',
            'time' => 'required|string',
            'description' => 'required|string',
            'location' => 'required|string',
            'type' => 'required|string',
        ]);

        $user = $request->user();
        
        // This would typically save to an events table
        // For now, return success response
        return response()->json([
            'status' => 200,
            'message' => 'Youth event created successfully',
            'event' => array_merge($validated, ['id' => rand(1000, 9999)])
        ], 201);
    }

    /**
     * Get youth ministry statistics
     */
    public function statistics(Request $request)
    {
        $user = $request->user();
        
        $congregation = $request->input('congregation');
        
        $query = Member::query();
        
        if ($congregation) {
            $query->where('congregation', $congregation);
        }
        
        // Youth statistics
        $totalYouth = $query->clone()
            ->whereRaw('TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) BETWEEN 18 AND 35')
            ->count();
            
        $activeYouth = $query->clone()
            ->whereRaw('TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) BETWEEN 18 AND 35')
            ->where('is_active', true)
            ->count();
            
        $maleYouth = $query->clone()
            ->whereRaw('TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) BETWEEN 18 AND 35')
            ->where('gender', 'male')
            ->count();
            
        $femaleYouth = $query->clone()
            ->whereRaw('TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) BETWEEN 18 AND 35')
            ->where('gender', 'female')
            ->count();
        
        return response()->json([
            'status' => 200,
            'statistics' => [
                'total_youth' => $totalYouth,
                'active_youth' => $activeYouth,
                'male_youth' => $maleYouth,
                'female_youth' => $femaleYouth,
                'scope' => compact('congregation')
            ]
        ]);
    }
}

