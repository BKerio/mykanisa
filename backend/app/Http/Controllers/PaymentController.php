<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Payment;
use App\Models\Member;

class PaymentController extends Controller
{
    public function status(Request $request)
    {
        $checkout = $request->query('checkout_request_id');
        if (!$checkout) {
            return response()->json(['status' => 400, 'message' => 'checkout_request_id is required'], 400);
        }

        $payment = Payment::where('checkout_request_id', $checkout)
            ->first(['id','checkout_request_id','mpesa_receipt_number','result_code','result_desc','status','created_at']);

        if (!$payment) {
            return response()->json([
                'status' => 200,
                'state' => 'pending',
                'message' => 'Processing payment, please check your phone',
            ]);
        }

        $state = 'pending';
        $message = 'Processing payment, please check your phone';
        if ($payment->status === 'confirmed' && $payment->mpesa_receipt_number) {
            $state = 'success';
            $message = 'Contribution Successful';
        } elseif ($payment->status === 'failed') {
            $state = 'failed';
            $message = $payment->result_desc ?: 'Payment failed';
        }

        return response()->json([
            'status' => 200,
            'state' => $state,
            'message' => $message,
            'result_code' => $payment->result_code,
            'result_desc' => $payment->result_desc,
            'mpesa_receipt_number' => $payment->mpesa_receipt_number,
            'created_at' => $payment->created_at,
        ]);
    }
    public function mine(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => 401, 'message' => 'Unauthorized'], 401);
        }

        $member = Member::where('email', $user->email)->first();
        if (!$member) {
            return response()->json(['status' => 404, 'message' => 'Member not found'], 404);
        }

        $ek = $member->e_kanisa_number;
        $phone = $member->telephone;

        $payments = Payment::query()
            ->when($ek, function($q) use ($ek) {
                $q->where('account_reference', 'like', $ek.'%');
            })
            ->when($phone, function($q) use ($phone) {
                $q->orWhere('phone', $phone);
            })
            ->orderBy('created_at', 'asc')
            ->get(['id','account_reference','phone','amount','mpesa_receipt_number','result_code','result_desc','created_at']);

        return response()->json([
            'status' => 200,
            'payments' => $payments,
            'full_name' => $member->full_name,
            'e_kanisa_number' => $ek,
            'congregation' => $member->congregation,
        ]);
    }
}






