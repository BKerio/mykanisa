<?php

namespace App\Http\Controllers\Secretary;

use App\Http\Controllers\Controller;
use App\Models\Member;
use App\Models\User;
use Illuminate\Http\Request;

class MembersController extends Controller
{
    /**
     * Display a listing of members (secretary can manage members)
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        $query = Member::query();
        
        $congregation = $request->input('congregation');
        $parish = $request->input('parish');
        $presbytery = $request->input('presbytery');
        
        if ($congregation) {
            $query->where('congregation', $congregation);
        }
        if ($parish) {
            $query->where('parish', $parish);
        }
        if ($presbytery) {
            $query->where('presbytery', $presbytery);
        }
        
        $members = $query->with(['dependencies', 'contributions', 'groups'])
            ->orderBy('full_name')
            ->get();
            
        return response()->json([
            'status' => 200,
            'members' => $members
        ]);
    }

    /**
     * Display the specified member
     */
    public function show(Request $request, Member $member)
    {
        $user = $request->user();
        
        $congregation = $request->input('congregation');
        
        if ($congregation && $member->congregation !== $congregation) {
            return response()->json(['message' => 'Access denied'], 403);
        }
        
        $member->load(['dependencies', 'contributions', 'groups', 'roles']);
        
        return response()->json([
            'status' => 200,
            'member' => $member
        ]);
    }

    /**
     * Create a new member (secretary can create members)
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
     * Update the specified member (secretary can update members)
     */
    public function update(Request $request, Member $member)
    {
        $user = $request->user();
        
        $congregation = $request->input('congregation');
        
        if ($congregation && $member->congregation !== $congregation) {
            return response()->json(['message' => 'Access denied'], 403);
        }
        
        $validated = $request->validate([
            'full_name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:members,email,' . $member->id,
            'telephone' => 'sometimes|string',
            'marital_status' => 'sometimes|string',
            'primary_school' => 'nullable|string',
            'is_baptized' => 'sometimes|boolean',
            'takes_holy_communion' => 'sometimes|boolean',
        ]);

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
        
        return response()->json([
            'status' => 200,
            'message' => 'Member updated successfully',
            'member' => $member
        ]);
    }
}

