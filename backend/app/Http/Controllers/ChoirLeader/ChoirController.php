<?php

namespace App\Http\Controllers\ChoirLeader;

use App\Http\Controllers\Controller;
use App\Models\Member;
use Illuminate\Http\Request;

class ChoirController extends Controller
{
    /**
     * Get choir members
     */
    public function members(Request $request)
    {
        $user = $request->user();
        
        // Get members who are part of choir group
        $query = Member::query();
        
        $congregation = $request->input('congregation');
        
        if ($congregation) {
            $query->where('congregation', $congregation);
        }
        
        // Filter by choir group (assuming 'Choir' is a group name)
        $query->whereHas('groups', function($q) {
            $q->where('name', 'LIKE', '%Choir%');
        });
        
        $members = $query->with(['groups'])
            ->orderBy('full_name')
            ->get();
            
        return response()->json([
            'status' => 200,
            'members' => $members
        ]);
    }

    /**
     * Add member to choir
     */
    public function addMember(Request $request)
    {
        $validated = $request->validate([
            'member_id' => 'required|exists:members,id',
        ]);

        $member = Member::findOrFail($validated['member_id']);
        
        // Check if member is in choir's scope
        $congregation = $request->input('congregation');
        if ($congregation && $member->congregation !== $congregation) {
            return response()->json(['message' => 'Access denied'], 403);
        }
        
        // Get or create choir group
        $choirGroup = \App\Models\Group::firstOrCreate(
            ['name' => 'Choir'],
            ['description' => 'Church Choir Group']
        );
        
        // Add member to choir group if not already a member
        if (!$member->groups()->where('group_id', $choirGroup->id)->exists()) {
            $member->groups()->attach($choirGroup->id);
            
            return response()->json([
                'status' => 200,
                'message' => 'Member added to choir successfully',
                'member' => $member->load('groups')
            ]);
        }
        
        return response()->json([
            'status' => 400,
            'message' => 'Member is already in the choir'
        ]);
    }

    /**
     * Remove member from choir
     */
    public function removeMember(Request $request, Member $member)
    {
        $user = $request->user();
        
        // Check if member is in choir's scope
        $congregation = $request->input('congregation');
        if ($congregation && $member->congregation !== $congregation) {
            return response()->json(['message' => 'Access denied'], 403);
        }
        
        // Get choir group
        $choirGroup = \App\Models\Group::where('name', 'Choir')->first();
        
        if ($choirGroup) {
            $member->groups()->detach($choirGroup->id);
            
            return response()->json([
                'status' => 200,
                'message' => 'Member removed from choir successfully'
            ]);
        }
        
        return response()->json([
            'status' => 400,
            'message' => 'Choir group not found'
        ]);
    }

    /**
     * Get choir events/activities
     */
    public function events(Request $request)
    {
        $user = $request->user();
        
        // This would typically come from an events table
        // For now, return mock data
        $events = [
            [
                'id' => 1,
                'title' => 'Weekly Choir Practice',
                'date' => now()->nextWeekday()->format('Y-m-d'),
                'time' => '19:00',
                'description' => 'Regular weekly choir practice session',
                'location' => 'Church Hall',
                'type' => 'practice'
            ],
            [
                'id' => 2,
                'title' => 'Sunday Service Performance',
                'date' => now()->nextSunday()->format('Y-m-d'),
                'time' => '10:00',
                'description' => 'Lead worship during Sunday service',
                'location' => 'Main Sanctuary',
                'type' => 'performance'
            ]
        ];
        
        return response()->json([
            'status' => 200,
            'events' => $events
        ]);
    }

}

