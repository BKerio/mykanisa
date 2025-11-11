<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Admin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $email = strtolower(trim($validated['email']));
        $password = trim($validated['password']);

        $admin = Admin::where('email', $email)->first();
        if (!$admin) {
            if (config('app.debug')) {
                \Log::warning('Admin login failed: email not found', ['email' => $email]);
            }
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        if (!Hash::check($password, $admin->password)) {
            if (config('app.debug')) {
                \Log::warning('Admin login failed: password mismatch', ['email' => $email]);
            }
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $token = $admin->createToken('admin')->plainTextToken;
        return response()->json([
            'token' => $token,
            'admin' => [
                'id' => $admin->id,
                'name' => $admin->name,
                'email' => $admin->email,
            ],
        ]);
    }

    public function me(Request $request)
    {
        /** @var Admin $admin */
        $admin = $request->user();
        return response()->json([
            'id' => $admin->id,
            'name' => $admin->name,
            'email' => $admin->email,
        ]);
    }

    public function logout(Request $request)
    {
        /** @var Admin $admin */
        $admin = $request->user();
        $admin->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out']);
    }
}
