<?php

namespace App\Http\Controllers\Elder;

use App\Http\Controllers\Controller;
use App\Models\Member;
use App\Models\Group;
use Illuminate\Http\Request;

class MembersController extends Controller
{
    /**
     * Display a listing of members (Elder has full admin access)
     */
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
     * Display the specified member
     */
    public function show(Request $request, Member $member)
    {
        // Elder has full permissions - fetch like admin
        $member->group_names = $this->getGroupNames($member->groups);
        return $member;
    }

    /**
     * Create a new member (elder can create members in their scope)
     */
    public function store(Request $request)
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
            'district' => 'nullable|string',
        ]);

        $validated['region'] = $request->input('region', 'Nairobi');
        $validated['is_active'] = true;
        
        $member = Member::create($validated);
        
        return response()->json([
            'status' => 200,
            'message' => 'Member created successfully',
            'member' => $member
        ], 201);
    }

    /**
     * Update the specified member
     */
    public function update(Request $request, Member $member)
    {
        // Elder has full permissions - update like admin
        $validated = $request->validate([
            'full_name' => 'sometimes|string|max:255',
            'telephone' => 'sometimes|string|max:50',
            'email' => 'sometimes|email',
            'role' => 'sometimes|string|in:member,deacon,elder,pastor,secretary,treasurer,choir_leader,youth_leader,chairman,sunday_school_teacher',
        ]);
        $member->update($validated);
        $member->group_names = $this->getGroupNames($member->groups);
        return $member;
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Member $member)
    {
        // Elder has full permissions - can delete members
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

