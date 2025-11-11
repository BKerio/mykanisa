<?php

namespace App\Http\Controllers\Chairman;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function me(Request $request)
    {
        return response()->json([
            'status' => 200,
            'user' => $request->user(),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();
        return response()->json(['status' => 200, 'message' => 'Logged out']);
    }
}



