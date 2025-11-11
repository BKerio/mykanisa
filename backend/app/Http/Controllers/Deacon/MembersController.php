<?php

namespace App\Http\Controllers\Deacon;

use App\Http\Controllers\Controller;
use App\Models\Member;
use Illuminate\Http\Request;

class MembersController extends Controller
{
    /**
     * Display a listing of members (deacon can create members in their scope)
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
            ->paginate(20);
            
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
     * Create a new member (deacon can create members in their scope)
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
}

