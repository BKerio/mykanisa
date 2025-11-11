<?php

namespace App\Http\Controllers\Chairman;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Member;

class MembersController extends Controller
{
    public function index(Request $request)
    {
        $members = Member::query()->latest()->paginate(20);
        return response()->json($members);
    }

    public function show(Member $member)
    {
        return response()->json($member);
    }

    public function update(Request $request, Member $member)
    {
        $validated = $request->validate([
            'full_name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email',
            'telephone' => 'sometimes|string|max:30',
            'congregation' => 'sometimes|string|max:100',
            'parish' => 'sometimes|string|max:100',
            'presbytery' => 'sometimes|string|max:100',
            'is_active' => 'sometimes|boolean',
        ]);

        $member->update($validated);
        return response()->json(['status' => 200, 'member' => $member]);
    }
}






