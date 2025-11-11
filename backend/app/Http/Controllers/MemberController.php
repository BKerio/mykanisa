<?php

namespace App\Http\Controllers;

use App\Models\Member;
use App\Models\Dependency;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;
use Illuminate\Support\Facades\Hash;
use App\Mail\WelcomeMemberMail;
use App\Services\SmsService;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class MemberController extends Controller
{
    public function register(Request $request)
    {
        // Handle JSON-encoded arrays from multipart form data
        $dependenciesInput = $request->input('dependencies');
        $groupIdsInput = $request->input('group_ids');
        
        if (is_string($dependenciesInput)) {
            $dependenciesInput = json_decode($dependenciesInput, true) ?? [];
            $request->merge(['dependencies' => $dependenciesInput]);
        }
        if (is_string($groupIdsInput)) {
            $groupIdsInput = json_decode($groupIdsInput, true) ?? [];
            $request->merge(['group_ids' => $groupIdsInput]);
        }
        
        // Handle boolean values from string inputs (multipart forms send as strings)
        if ($request->has('is_baptized') && is_string($request->input('is_baptized'))) {
            $request->merge(['is_baptized' => $request->input('is_baptized') === 'true']);
        }
        if ($request->has('takes_holy_communion') && is_string($request->input('takes_holy_communion'))) {
            $request->merge(['takes_holy_communion' => $request->input('takes_holy_communion') === 'true']);
        }
        
        $validated = $request->validate([
            'full_name' => 'required|string|max:255',
            'date_of_birth' => 'required|date',
            'national_id' => 'nullable|string|max:50',
            'email' => 'required|email|unique:members,email',
            'gender' => 'required|in:Male,Female',
            'marital_status' => 'required|in:Single,Married (Customary),Married (Church Wedding),Divorced,Widow,Widower,Separated',
            'is_baptized' => 'boolean',
            'takes_holy_communion' => 'boolean',
            'region' => 'required|string|max:100',
            'presbytery' => 'required|string|max:100',
            'parish' => 'required|string|max:100',
            'district' => 'required|string|max:100',
            'congregation' => 'required|string|max:100',
            'telephone' => 'nullable|string|max:30',
            'password' => 'required|min:6|confirmed',
            'profile_image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'dependencies' => 'array',
            'group_ids' => 'array',
            'group_ids.*' => 'integer|exists:groups,id',
            'dependencies.*.name' => 'required_with:dependencies|string|max:255',
            'dependencies.*.year_of_birth' => 'required_with:dependencies|integer|min:1900|max:'.date('Y'),
            'dependencies.*.birth_cert_number' => 'nullable|digits:9',
            'dependencies.*.is_baptized' => 'boolean',
            'dependencies.*.takes_holy_communion' => 'boolean',
            'dependencies.*.school' => 'nullable|string|max:255',
        ]);

        // Age auto-calc and national_id rule for 18+
        $age = Carbon::parse($validated['date_of_birth'])->age;
        if ($age >= 18 && empty($validated['national_id'])) {
            return response()->json(['status' => 422, 'message' => 'National ID is required for members aged 18+'], 422);
        }

        $ekanisa = $this->generateEkanisaNumber();

        return DB::transaction(function () use ($validated, $age, $ekanisa, $request) {
            // Handle profile image upload if provided
            $profileImagePath = null;
            if ($request->hasFile('profile_image')) {
                try {
                    $profileImagePath = $request->file('profile_image')->store('profiles', 'public');
                } catch (\Exception $e) {
                    Log::error('Failed to upload profile image during registration', [
                        'error' => $e->getMessage(),
                    ]);
                    // Continue registration even if image upload fails
                }
            }

            $member = Member::create([
                'full_name' => $validated['full_name'],
                'date_of_birth' => $validated['date_of_birth'],
                'age' => $age,
                'national_id' => $validated['national_id'] ?? null,
                'email' => $validated['email'],
                'gender' => $validated['gender'],
                'marital_status' => $validated['marital_status'],
                'is_baptized' => (bool)($validated['is_baptized'] ?? false),
                'takes_holy_communion' => (bool)($validated['takes_holy_communion'] ?? false),
                'region' => $validated['region'],
                'presbytery' => $validated['presbytery'],
                'parish' => $validated['parish'],
                'district' => $validated['district'],
                'congregation' => $validated['congregation'],
                'groups' => !empty($validated['group_ids']) ? json_encode($validated['group_ids']) : null,
                'e_kanisa_number' => $ekanisa,
                'telephone' => $validated['telephone'] ?? null,
                'profile_image' => $profileImagePath,
            ]);

            foreach (($validated['dependencies'] ?? []) as $dep) {
                // Prevent duplicates for THIS member only
                $query = Dependency::where('member_id', $member->id);
                if (!empty($dep['birth_cert_number'])) {
                    $query->where('birth_cert_number', $dep['birth_cert_number']);
                } else {
                    $query->where('name', $dep['name'])
                          ->where('year_of_birth', $dep['year_of_birth']);
                }
                $existing = $query->first();
                if ($existing) {
                    continue; // skip duplicates for this member
                }

                Dependency::create([
                    'member_id' => $member->id,
                    'name' => $dep['name'],
                    'year_of_birth' => $dep['year_of_birth'],
                    'birth_cert_number' => $dep['birth_cert_number'] ?? null,
                    'is_baptized' => (bool)($dep['is_baptized'] ?? false),
                    'takes_holy_communion' => (bool)($dep['takes_holy_communion'] ?? false),
                    'school' => $dep['school'] ?? null,
                ]);
            }

            try {
                Mail::to($member->email)->send(new WelcomeMemberMail($member));
            } catch (\Exception $e) {
                Log::error('Failed to send welcome email to new member', [
                    'member_id' => $member->id,
                    'email' => $member->email,
                    'error' => $e->getMessage(),
                ]);
            }

            // Send welcome SMS if phone number is provided
        if (!empty($member->telephone)) {
            try {
                $smsService = new SmsService();
                $welcomeMessage = "Welcome to PCEA {$member->congregation}, {$member->full_name}! 🎉 "
                    . "My Kanisa Number is {$member->e_kanisa_number}. "
                    . "You can now log in to your account to manage your membership, "
                    . "stay connected, and grow with us.";
                
                $smsService->sendSms($member->telephone, $welcomeMessage);
            } catch (\Exception $e) {
               
            }
        }

            // Create or update a login account for this member (mandatory password)
            $user = User::where('email', $validated['email'])->first();
            if ($user) {
                $user->name = $validated['full_name'];
                $user->password = Hash::make($validated['password']);
                $user->save();
            } else {
                User::create([
                    'name' => $validated['full_name'],
                    'email' => $validated['email'],
                    'password' => Hash::make($validated['password']),
                ]);
            }

            $memberData = $member->toArray();
            if ($member->profile_image) {
                $memberData['profile_image_url'] = asset('storage/'.$member->profile_image);
            }

            return response()->json([
                'status' => 200,
                'member' => $memberData
            ]);
        });
    }

#------------Start od our Logic to generate  PCEA E-Kanisa number----------------
   private function generateEkanisaNumber(): string
{
    $letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    $digits  = '23456789';

    do {
        
        $digitArray = str_split($digits);
        shuffle($digitArray);
        $digitPart = implode('', array_slice($digitArray, 0, 3));

        $letterArray = str_split($letters);
        shuffle($letterArray);
        $letterPart = implode('', array_slice($letterArray, 0, 3));

        $code = 'PCEA-' . $digitPart . $letterPart;

    } while (\App\Models\Member::where('e_kanisa_number', $code)->exists());

    return $code;
}


    //------------End of our Logic to generate  PCEA My Kanisa number----------------
    public function me(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 401, 'message' => 'Unauthorized'], 401);
        }
        $member = Member::where('email', $user->email)->first();
        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }
        $memberArray = $member->toArray();
        if (!empty($member->profile_image)) {
            $memberArray['profile_image_url'] = asset('storage/'.$member->profile_image);
        }
        if (!empty($member->passport_image)) {
            $memberArray['passport_image_url'] = asset('storage/'.$member->passport_image);
        }
        return response()->json(['status' => 200, 'member' => $memberArray]);
    }

    /**
     * Get members for minutes page (authenticated users)
     */
    public function getMembersForMinutes(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 401, 'message' => 'Unauthorized'], 401);
        }

        $query = Member::query();
        
        // Filter by congregation if user has a specific congregation
        $member = Member::where('email', $user->email)->first();
        if ($member && $member->congregation) {
            $query->where('congregation', $member->congregation);
        }
        
        $members = $query->select(['id', 'full_name', 'e_kanisa_number', 'congregation'])
            ->orderBy('full_name')
            ->get();
            
        return response()->json([
            'status' => 200,
            'members' => $members
        ]);
    }

    public function updateMe(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 401, 'message' => 'Unauthorized'], 401);
        }
        $member = Member::where('email', $user->email)->first();
        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        $validated = $request->validate([
            'full_name' => 'sometimes|required|string|max:255',
            'date_of_birth' => 'sometimes|required|date',
            'national_id' => 'nullable|string|max:50',
            'gender' => 'sometimes|required|in:Male,Female',
            'marital_status' => 'sometimes|required|in:Single,Married (Customary),Married (Church Wedding),Divorced,Widow,Widower,Separated',
            'is_baptized' => 'boolean',
            'takes_holy_communion' => 'boolean',
            'presbytery' => 'sometimes|required|string|max:100',
            'parish' => 'sometimes|required|string|max:100',
            'congregation' => 'sometimes|required|string|max:100',
            'groups' => 'nullable|string',
            'telephone' => 'nullable|string|max:30',
            'location_county' => 'nullable|string|max:100',
            'location_subcounty' => 'nullable|string|max:100',
        ]);

        if (array_key_exists('date_of_birth', $validated)) {
            $validated['age'] = Carbon::parse($validated['date_of_birth'])->age;
        }

        $member->fill($validated);
        $member->save();

        return response()->json(['status' => 200, 'member' => $member, 'message' => 'Profile updated']);
    }

    public function updateAvatar(Request $request)
    {
        Log::info('updateAvatar called', [
            'user_id' => $request->user()?->id,
            'user_email' => $request->user()?->email,
            'has_file' => $request->hasFile('image'),
        ]);
        
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 401, 'message' => 'Unauthorized'], 401);
        }
        
        $member = Member::where('email', $user->email)->first();
        if (!$member) {
            Log::error('Member not found for user', [
                'user_id' => $user->id,
                'user_email' => $user->email,
            ]);
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        $request->validate([
            'image' => 'required|image|mimes:jpg,jpeg,png|max:2048',
        ]);

        try {
            Log::info('Processing avatar upload', [
                'member_id' => $member->id,
                'email' => $member->email,
                'has_file' => $request->hasFile('image'),
            ]);
            
            // Delete old profile image if exists
            if ($member->profile_image && Storage::disk('public')->exists($member->profile_image)) {
                Storage::disk('public')->delete($member->profile_image);
            }
            
            $path = $request->file('image')->store('profiles', 'public');
            $member->profile_image = $path;
            $member->save();
            
            Log::info('Member profile_image updated successfully', [
                'member_id' => $member->id,
                'email' => $member->email,
                'profile_image' => $path,
            ]);
        } catch (\Throwable $e) {
            Log::error('Failed to update profile_image', [
                'member_id' => $member->id ?? null,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            return response()->json([
                'status' => 500,
                'message' => 'Failed to save profile image: ' . $e->getMessage()
            ], 500);
        }

        return response()->json([
            'status' => 200,
            'message' => 'Profile image updated successfully',
            'profile_image' => $path,
            'profile_image_url' => asset('storage/'.$path)
        ]);
    }

    public function updatePassport(Request $request)
    {
        Log::info('updatePassport called', [
            'user_id' => $request->user()?->id,
            'user_email' => $request->user()?->email,
            'has_file' => $request->hasFile('image'),
        ]);
        
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 401, 'message' => 'Unauthorized'], 401);
        }
        
        $member = Member::where('email', $user->email)->first();
        if (!$member) {
            Log::error('Member not found for user', [
                'user_id' => $user->id,
                'user_email' => $user->email,
            ]);
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        $request->validate([
            'image' => 'required|image|mimes:jpg,jpeg,png|max:2048',
        ]);

        try {
            Log::info('Processing passport upload', [
                'member_id' => $member->id,
                'email' => $member->email,
                'has_file' => $request->hasFile('image'),
            ]);
            
            // Delete old passport image if exists
            if ($member->passport_image && Storage::disk('public')->exists($member->passport_image)) {
                Storage::disk('public')->delete($member->passport_image);
            }
            
            $path = $request->file('image')->store('passports', 'public');
            $member->passport_image = $path;
            $member->save();
            
            Log::info('Member passport_image updated successfully', [
                'member_id' => $member->id,
                'email' => $member->email,
                'passport_image' => $path,
            ]);
        } catch (\Throwable $e) {
            Log::error('Failed to update passport_image', [
                'member_id' => $member->id ?? null,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            return response()->json([
                'status' => 500,
                'message' => 'Failed to save passport image: ' . $e->getMessage()
            ], 500);
        }

        return response()->json([
            'status' => 200,
            'message' => 'Passport image updated successfully',
            'passport_image' => $path,
            'passport_image_url' => asset('storage/'.$path)
        ]);
    }

    public function updateDependentImage(Request $request, $id)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 401, 'message' => 'Unauthorized'], 401);
        }
        $member = Member::where('email', $user->email)->first();
        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        $dependent = Dependency::where('id', $id)->where('member_id', $member->id)->first();
        if (!$dependent) {
            return response()->json(['status' => 404, 'message' => 'Dependent not found'], 404);
        }

        $request->validate([
            'image' => 'required|image|mimes:jpg,jpeg,png|max:2048',
        ]);

        $path = $request->file('image')->store('dependents', 'public');
        $dependent->image = $path;
        $dependent->save();

        return response()->json([
            'status' => 200,
            'image' => $path,
            'image_url' => asset('storage/'.$path)
        ]);
    }

    public function getDependents(Request $request)
    {
        $user = $request->user();
        $member = Member::where('email', $user->email)->first();

        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        $dependents = Dependency::where('member_id', $member->id)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function($dep) {
                $arr = $dep->toArray();
                if (!empty($dep->image)) {
                    $arr['image_url'] = asset('storage/'.$dep->image);
                }
                return $arr;
            });

        return response()->json([
            'status' => 200,
            'dependents' => $dependents
        ]);
    }

    public function addDependent(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'year_of_birth' => 'required|integer|min:1900|max:' . date('Y'),
            'birth_cert_number' => 'nullable|digits:9',
            'is_baptized' => 'boolean',
            'takes_holy_communion' => 'boolean',
            'school' => 'nullable|string|max:255',
        ]);

        $user = $request->user();
        $member = Member::where('email', $user->email)->first();

        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        // Check for duplicate dependents globally (across all members)
        $duplicateCheck = Dependency::where('name', $validated['name'])
            ->where('year_of_birth', $validated['year_of_birth'])
            ->when($validated['birth_cert_number'], function($query, $certNumber) {
                return $query->where('birth_cert_number', $certNumber);
            })
            ->first();

        if ($duplicateCheck) {
            return response()->json([
                'status' => 409,
                'message' => 'A dependent with this name, birth year' . 
                           ($validated['birth_cert_number'] ? ', and birth certificate number' : '') . 
                           ' already exists in the system.'
            ], 409);
        }

        // Create new dependent
        $dependent = new Dependency([
            'member_id' => $member->id,
            'name' => $validated['name'],
            'year_of_birth' => $validated['year_of_birth'],
            'birth_cert_number' => $validated['birth_cert_number'],
            'is_baptized' => $validated['is_baptized'] ?? false,
            'takes_holy_communion' => $validated['takes_holy_communion'] ?? false,
            'school' => $validated['school'],
        ]);

        $dependent->save();

        return response()->json([
            'status' => 200,
            'message' => 'Dependent added successfully',
            'dependent' => $dependent
        ]);
    }

    public function updateDependent(Request $request, $id)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'year_of_birth' => 'required|integer|min:1900|max:' . date('Y'),
            'birth_cert_number' => 'nullable|digits:9',
            'is_baptized' => 'boolean',
            'takes_holy_communion' => 'boolean',
            'school' => 'nullable|string|max:255',
        ]);

        $user = $request->user();
        $member = Member::where('email', $user->email)->first();

        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        $dependent = Dependency::where('id', $id)
            ->where('member_id', $member->id)
            ->first();

        if (!$dependent) {
            return response()->json(['status' => 404, 'message' => 'Dependent not found'], 404);
        }

        // Check for duplicate dependents globally (excluding current one)
        $duplicateCheck = Dependency::where('name', $validated['name'])
            ->where('year_of_birth', $validated['year_of_birth'])
            ->when($validated['birth_cert_number'], function($query, $certNumber) {
                return $query->where('birth_cert_number', $certNumber);
            })
            ->where('id', '!=', $id)
            ->first();

        if ($duplicateCheck) {
            return response()->json([
                'status' => 409,
                'message' => 'A dependent with this name, birth year' . 
                           ($validated['birth_cert_number'] ? ', and birth certificate number' : '') . 
                           ' already exists in the system.'
            ], 409);
        }

        // Update dependent
        $dependent->update([
            'name' => $validated['name'],
            'year_of_birth' => $validated['year_of_birth'],
            'birth_cert_number' => $validated['birth_cert_number'],
            'is_baptized' => $validated['is_baptized'] ?? false,
            'takes_holy_communion' => $validated['takes_holy_communion'] ?? false,
            'school' => $validated['school'],
        ]);

        return response()->json([
            'status' => 200,
            'message' => 'Dependent updated successfully',
            'dependent' => $dependent
        ]);
    }

}


