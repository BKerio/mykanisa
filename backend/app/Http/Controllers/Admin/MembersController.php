<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Member;
use App\Models\Group;
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
        ]);
        $member->update($validated);
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
