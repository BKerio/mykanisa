<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Member;
use App\Models\Group;
use App\Models\User;
use Illuminate\Http\Request;

class MembersController extends Controller
{
    public function index(Request $request)
    {
        $perPage = (int)($request->query('per_page', 20));
        $search = trim((string)$request->query('q', ''));

        $query = Member::query();
        if ($search !== '') {
            $query->where(function($q) use ($search) {
                $q->where('full_name', 'like', "%{$search}%")
                  ->orWhere('e_kanisa_number', 'like', "%{$search}%")
                  ->orWhere('telephone', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $members = $query->orderByDesc('id')->paginate($perPage);
        
        // Transform the data to include group names
        $members->getCollection()->transform(function ($member) {
            $member->group_names = $this->getGroupNames($member->groups);
            return $member;
        });

        return $members;
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function show(Member $member)
    {
        $member->group_names = $this->getGroupNames($member->groups);
        return $member;
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, Member $member)
    {
        $validated = $request->validate([
            'full_name' => 'sometimes|string|max:255',
            'telephone' => 'sometimes|string|max:50',
            'email' => 'sometimes|email',
            'role' => 'sometimes|string|in:member,deacon,elder,pastor,secretary,treasurer,choir_leader,youth_leader,chairman,sunday_school_teacher',
            'assigned_group_id' => 'nullable|exists:groups,id',
        ]);
        
        // Special handling for youth_leader role assignment
        if (isset($validated['role']) && $validated['role'] === 'youth_leader') {
            if (isset($validated['assigned_group_id'])) {
                $groupId = $validated['assigned_group_id'];
                
                // Verify that the member is actually a member of the group
                if (!$member->isMemberOfGroup($groupId)) {
                    return response()->json([
                        'status' => 400,
                        'message' => 'Member must be a member of the group before being assigned as youth leader'
                    ], 400);
                }
                
                // Set the assigned group
                $validated['assigned_group_id'] = $groupId;
            } else {
                // If role is being changed to youth_leader but no group assigned, require it
                if ($member->role !== 'youth_leader') {
                    return response()->json([
                        'status' => 400,
                        'message' => 'Youth leader must be assigned to a group. Please specify assigned_group_id'
                    ], 400);
                }
            }
        } else {
            // If role is being changed from youth_leader, clear assigned group
            if ($member->role === 'youth_leader' && isset($validated['role']) && $validated['role'] !== 'youth_leader') {
                $validated['assigned_group_id'] = null;
            }
        }
        
        $member->update($validated);
        
        // Also update the corresponding user's name if full_name was updated
        // This ensures consistency across all related tables (members and users)
        if (array_key_exists('full_name', $validated)) {
            $user = User::where('email', $member->email)->first();
            if ($user) {
                $user->name = $validated['full_name'];
                $user->save();
            }
        }
        
        // Load assigned group relationship if applicable
        if ($member->role === 'youth_leader' && $member->assigned_group_id) {
            $member->load('assignedGroup');
        }
        
        return $member;
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function destroy(Member $member)
    {
        $member->delete();
        return response()->json(['message' => 'Deleted']);
    }

    /**
     * Get group names from group IDs JSON string
     */
    private function getGroupNames($groupsJson)
    {
        if (empty($groupsJson)) {
            return [];
        }

        try {
            $groupIds = json_decode($groupsJson, true);
            if (!is_array($groupIds)) {
                return [];
            }

            $groups = Group::whereIn('id', $groupIds)->pluck('name')->toArray();
            return $groups;
        } catch (\Exception $e) {
            return [];
        }
    }
}
