<?php

namespace App\Http\Controllers\Member;

use App\Http\Controllers\Controller;
use App\Models\Member;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    /**
     * Get member's own profile
     */
    public function show(Request $request)
    {
        $user = $request->user();
        
        // Members can only view their own profile
        $member = Member::with(['dependencies', 'contributions', 'groups', 'roles'])
            ->find($user->id);
            
        return response()->json([
            'status' => 200,
            'member' => $member
        ]);
    }

    /**
     * Update member's own profile
     */
    public function update(Request $request)
    {
        $user = $request->user();
        $member = Member::find($user->id);
        
        $validated = $request->validate([
            'full_name' => 'sometimes|string|max:255',
            'telephone' => 'sometimes|string',
            'email' => 'sometimes|email|unique:members,email,' . $member->id,
            'marital_status' => 'sometimes|string',
            'primary_school' => 'nullable|string',
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
            'message' => 'Profile updated successfully',
            'member' => $member->fresh()
        ]);
    }

    /**
     * Update profile image
     */
    public function updateAvatar(Request $request)
    {
        $user = $request->user();
        $member = Member::find($user->id);
        
        $request->validate([
            'avatar' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048'
        ]);

        if ($request->hasFile('avatar')) {
            // Delete old avatar if exists
            if ($member->profile_image && Storage::disk('public')->exists($member->profile_image)) {
                Storage::disk('public')->delete($member->profile_image);
            }

            // Store new avatar
            $path = $request->file('avatar')->store('profiles', 'public');
            $member->update(['profile_image' => $path]);
            
            return response()->json([
                'status' => 200,
                'message' => 'Avatar updated successfully',
                'profile_image' => $path
            ]);
        }

        return response()->json([
            'status' => 400,
            'message' => 'No image provided'
        ]);
    }

    /**
     * Update passport image
     */
    public function updatePassport(Request $request)
    {
        $user = $request->user();
        $member = Member::find($user->id);
        
        $request->validate([
            'passport' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048'
        ]);

        if ($request->hasFile('passport')) {
            // Delete old passport if exists
            if ($member->passport_image && Storage::disk('public')->exists($member->passport_image)) {
                Storage::disk('public')->delete($member->passport_image);
            }

            // Store new passport
            $path = $request->file('passport')->store('passports', 'public');
            $member->update(['passport_image' => $path]);
            
            return response()->json([
                'status' => 200,
                'message' => 'Passport updated successfully',
                'passport_image' => $path
            ]);
        }

        return response()->json([
            'status' => 400,
            'message' => 'No passport image provided'
        ]);
    }
}

