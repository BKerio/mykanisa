<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Member;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use App\Mail\ResetCodeMail;
use App\Services\SmsService;

class AuthController extends Controller
{
    function Register(Request $R)
    {
        try {
            $cred = new User();
            $cred->name = $R->name;
            $cred->email = $R->email;
            $cred->password = Hash::make($R->password);
            $cred->save();

            $response = [
                'status' => 200,
                'message' => 'Member Registered Successfully! Welcome to Our Church Community'
            ];
            return response()->json($response);

        } catch (Exception $e) {
            $response = ['status' => 500, 'message' => $e->getMessage()];
            return response()->json($response);
        }
    }

    function Login(Request $R)
    {
        $identifier = $R->input('identifier', $R->input('email'));
        $password = $R->input('password');

        $user = null;
        if ($identifier) {
            if (filter_var($identifier, FILTER_VALIDATE_EMAIL)) {
                $user = User::where('email', $identifier)->first();
            } else {
                $member = Member::where('e_kanisa_number', $identifier)->first();
                if ($member) {
                    $user = User::where('email', $member->email)->first();
                }
            }
        }

        if ($user && Hash::check($password, $user->password)) {
            // Create token without expiration (tokens never expire unless explicitly deleted on logout)
            $token = $user->createToken('Personal Access Token')->plainTextToken;

            $member = Member::where('email', $user->email)->first();
            $user->e_kanisa_number = $member ? $member->e_kanisa_number : null;

            return response()->json([
                'status' => 200,
                'token' => $token,
                'user' => $user,
                'message' => 'Successfully Login! Welcome Back to our Church  Community'
            ]);
        } elseif (!$user) {
            return response()->json(['status' => 500, 'message' => 'No account found with this email']);
        } else {
            return response()->json(['status' => 500, 'message' => 'Wrong email or password! please try again']);
        }
    }

    function forgotPassword(Request $R)
    {
        $R->validate([
            'identifier' => 'required',
            'channel' => 'nullable|in:email,sms',
        ]);

        $identifier = $R->input('identifier');
        $channel = $R->input('channel', 'email');
        $email = null;
        $member = null;

        // Helper: normalize phone numbers to E.164-like 2547XXXXXXXX format commonly used in KE
        $normalizePhone = function(string $raw): string {
            $digits = preg_replace('/[^0-9]/', '', $raw ?? '');
            if (!$digits) return '';
            if (str_starts_with($digits, '0')) {
                return '254' . substr($digits, 1);
            }
            if (str_starts_with($digits, '254')) {
                return $digits;
            }
            if (str_starts_with($digits, '7')) {
                return '254' . $digits;
            }
            return $digits;
        };

        if (filter_var($identifier, FILTER_VALIDATE_EMAIL)) {
            $email = $identifier;
        } else {
            // Try E-Kanisa number first
            $member = Member::where('e_kanisa_number', $identifier)->first();
            // If not found, try by telephone (accepts 07XXXXXXXX, 7XXXXXXXX, or 2547XXXXXXXX)
            if (!$member) {
                $normalized = $normalizePhone($identifier);
                if (!empty($normalized)) {
                    $member = Member::where(function($q) use ($normalized) {
                        $q->where('telephone', $normalized)
                          ->orWhere('telephone', '0' . substr($normalized, 3))
                          ->orWhere('telephone', substr($normalized, 3));
                    })->first();
                }
            }
            if ($member) {
                $email = $member->email;
            }
        }

        if (!$email) {
            return response()->json(['status' => 404, 'message' => 'No account found for provided identifier'], 404);
        }

        $user = User::where('email', $email)->first();
        if (!$user) {
            return response()->json(['status' => 404, 'message' => 'No user account found for this email'], 404);
        }

        $code = random_int(100000, 999999);
        $hashedCode = Hash::make((string)$code);

        DB::table('password_resets')->updateOrInsert(
            ['email' => $email],
            ['token' => $hashedCode, 'created_at' => now()]
        );

        try {
            if ($channel === 'sms') {
                if (!$member) {
                    $member = Member::where('email', $email)->first();
                }
                if (!$member || empty($member->telephone)) {
                    return response()->json(['status' => 422, 'message' => 'No phone number found for this account'], 422);
                }

                $smsText = 'Your password reset code is ' . $code . '. It expires in 15 minutes.';
                $smsService = new SmsService();
                $sent = $smsService->sendSms($member->telephone, $smsText);

                if (!$sent) {
                    return response()->json(['status' => 500, 'message' => 'Failed to send SMS']);
                }

                return response()->json([
                    'status' => 200,
                    'message' => 'Reset code sent via SMS',
                    'email' => $email,
                    'phone' => $member->telephone,
                ]);
            } else {
                Mail::to($email)->send(new ResetCodeMail($code));
                return response()->json([
                    'status' => 200,
                    'message' => 'Reset code sent to email',
                    'email' => $email
                ]);
            }
        } catch (Exception $e) {
            Log::error('Reset code send failed: ' . $e->getMessage());
            return response()->json(['status' => 500, 'message' => 'Failed to send reset code']);
        }
    }

    function verifyResetCode(Request $R)
    {
        $R->validate([
            'identifier' => 'required',
            'code' => 'required|digits:6',
        ]);

        $identifier = $R->input('identifier');
        $email = null;

        $normalizePhone = function(string $raw): string {
            $digits = preg_replace('/[^0-9]/', '', $raw ?? '');
            if (!$digits) return '';
            if (str_starts_with($digits, '0')) {
                return '254' . substr($digits, 1);
            }
            if (str_starts_with($digits, '254')) {
                return $digits;
            }
            if (str_starts_with($digits, '7')) {
                return '254' . $digits;
            }
            return $digits;
        };

        if (filter_var($identifier, FILTER_VALIDATE_EMAIL)) {
            $email = $identifier;
        } else {
            $member = Member::where('e_kanisa_number', $identifier)->first();
            if (!$member) {
                $normalized = $normalizePhone($identifier);
                if (!empty($normalized)) {
                    $member = Member::where(function($q) use ($normalized) {
                        $q->where('telephone', $normalized)
                          ->orWhere('telephone', '0' . substr($normalized, 3))
                          ->orWhere('telephone', substr($normalized, 3));
                    })->first();
                }
            }
            if ($member) {
                $email = $member->email;
            }
        }

        if (!$email) {
            Log::info('No email found for identifier: ' . $identifier);
            return response()->json(['status' => 404, 'message' => 'No account found for provided identifier'], 404);
        }

        Log::info('Verifying reset code for email: ' . $email);
        Log::info('Code provided: ' . $R->code);

        $record = DB::table('password_resets')->where('email', $email)->first();
        if (!$record) {
            Log::info('No reset request found for email: ' . $email);
            return response()->json(['status' => 404, 'message' => 'No reset request found'], 404);
        }

        $expired = Carbon::parse($record->created_at)->addMinutes(15)->isPast();
        if ($expired) {
            Log::info('Reset code expired for email: ' . $email);
            return response()->json(['status' => 410, 'message' => 'Reset code expired'], 410);
        }

        $isValid = Hash::check((string)$R->code, $record->token);
        Log::info('Code validation result: ' . ($isValid ? 'valid' : 'invalid'));

        if (!$isValid) {
            return response()->json(['status' => 422, 'message' => 'Invalid code'], 422);
        }

        return response()->json([
            'status' => 200,
            'message' => 'Code verified',
            'email' => $email
        ]);
    }

    function resetPassword(Request $R)
    {
        $R->validate([
            'email' => 'required|email',
            'code' => 'required|digits:6',
            'password' => 'required|min:6|confirmed',
        ]);

        Log::info('Resetting password for email: ' . $R->email);
        Log::info('Code provided: ' . $R->code);

        $record = DB::table('password_resets')->where('email', $R->email)->first();
        if (!$record) {
            Log::info('No reset request found for email: ' . $R->email);
            return response()->json(['status' => 404, 'message' => 'No reset request found'], 404);
        }

        $expired = Carbon::parse($record->created_at)->addMinutes(15)->isPast();
        if ($expired) {
            Log::info('Reset code expired for email: ' . $R->email);
            return response()->json(['status' => 410, 'message' => 'Reset code expired'], 410);
        }

        $isValid = Hash::check((string)$R->code, $record->token);
        Log::info('Code validation result: ' . ($isValid ? 'valid' : 'invalid'));

        if (!$isValid) {
            return response()->json(['status' => 422, 'message' => 'Invalid code'], 422);
        }

        $user = User::where('email', $R->email)->first();
        if (!$user) {
            Log::info('No user found for email: ' . $R->email);
            return response()->json(['status' => 404, 'message' => 'No account found with this email'], 404);
        }

        $user->password = Hash::make($R->password);
        $user->save();

        DB::table('password_resets')->where('email', $R->email)->delete();

        Log::info('Password reset successfully for email: ' . $R->email);
        return response()->json(['status' => 200, 'message' => 'Password reset successful']);
    }
}
