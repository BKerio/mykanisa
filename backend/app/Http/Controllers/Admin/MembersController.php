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
            'role' => 'sometimes|string|in:member,deacon,elder,pastor,secretary,treasurer,choir_leader,group_leader,chairman,sunday_school_teacher',
            'assigned_group_ids' => 'nullable|array',
            'assigned_group_ids.*' => 'exists:groups,id',
        ]);
        
        // Special handling for group_leader role assignment
        if (isset($validated['role']) && $validated['role'] === 'group_leader') {
            if (!empty($validated['assigned_group_ids'])) {
                $groupIds = $validated['assigned_group_ids'];
                
                // Verify that the member is actually a member of ALL selected groups
                foreach ($groupIds as $groupId) {
                    if (!$member->isMemberOfGroup($groupId)) {
                        $group = Group::find($groupId);
                        return response()->json([
                            'status' => 400,
                            'message' => "Member must be a member of '{$group->name}' before being assigned as its leader"
                        ], 400);
                    }
                }
                
                // Set the assigned groups (automatically cast to JSON by model)
                $validated['assigned_group_ids'] = $groupIds;
            } else {
                // If role is being changed to group_leader but no group assigned, require it
                // Only if not already a group leader with assigned groups
                // Or if we are explicitly clearing them
                if ($member->role !== 'group_leader' || isset($validated['assigned_group_ids'])) {
                    return response()->json([
                        'status' => 400,
                        'message' => 'Group leader must be assigned to at least one group.'
                    ], 400);
                }
            }
        } else {
            // If role is being changed from group_leader (and not to group_leader), clear assigned groups
            if ($member->role === 'group_leader' && isset($validated['role']) && $validated['role'] !== 'group_leader') {
                $validated['assigned_group_ids'] = null;
            }
        }
        
        $member->update($validated);
        
        // Also update the corresponding user's name if full_name was updated
        if (array_key_exists('full_name', $validated)) {
            $user = User::where('email', $member->email)->first();
            if ($user) {
                $user->name = $validated['full_name'];
                $user->save();
            }
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
