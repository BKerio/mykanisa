<?php

namespace App\Http\Controllers;

use App\Models\Member;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class QRController extends Controller
{
    /**
     * Verify member data from QR code
     */
    public function verifyQR(Request $request)
    {
        $request->validate([
            'e_kanisa_number' => 'required|string',
        ]);

        try {
            $member = Member::where('e_kanisa_number', $request->e_kanisa_number)
                ->where('is_active', true)
                ->first();

            if (!$member) {
                return response()->json([
                    'status' => 404,
                    'message' => 'Member not found or inactive',
                    'valid' => false
                ], 404);
            }

            return response()->json([
                'status' => 200,
                'message' => 'Member verified successfully',
                'valid' => true,
                'member' => [
                    'id' => $member->id,
                    'e_kanisa_number' => $member->e_kanisa_number,
                    'full_name' => $member->full_name,
                    'email' => $member->email,
                    'congregation' => $member->congregation,
                    'parish' => $member->parish,
                    'presbytery' => $member->presbytery,
                    'region' => $member->region,
                    'is_active' => $member->is_active,
                    'created_at' => $member->created_at,
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('QR verification error: ' . $e->getMessage());
            
            return response()->json([
                'status' => 500,
                'message' => 'Internal server error',
                'valid' => false
            ], 500);
        }
    }

    /**
     * Get member data for QR code generation
     */
    public function getMemberForQR(Request $request)
    {
        $user = $request->user();
        
        if (!$user) {
            return response()->json([
                'status' => 401,
                'message' => 'Unauthorized'
            ], 401);
        }

        $member = Member::where('email', $user->email)->first();

        if (!$member) {
            return response()->json([
                'status' => 404,
                'message' => 'Member not found'
            ], 404);
        }

        return response()->json([
            'status' => 200,
            'member' => [
                'id' => $member->id,
                'e_kanisa_number' => $member->e_kanisa_number,
                'full_name' => $member->full_name,
                'email' => $member->email,
                'congregation' => $member->congregation,
                'parish' => $member->parish,
                'presbytery' => $member->presbytery,
                'region' => $member->region,
                'is_active' => $member->is_active,
            ]
        ]);
    }
}
