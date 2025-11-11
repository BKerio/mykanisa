<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    use HasFactory;

    protected $fillable = [
        'merchant_request_id',
        'checkout_request_id',
        'account_reference',
        'phone',
        'amount',
        'mpesa_receipt_number',
        'result_code',
        'result_desc',
        'status',
        'member_id',
    ];

    public function member()
    {
        return $this->belongsTo(Member::class);
    }

    public function contributions()
    {
        return $this->hasMany(Contribution::class);
    }
}
