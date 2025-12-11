<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Attendance extends Model
{
    use HasFactory;

    protected $fillable = [
        'member_id',
        'e_kanisa_number',
        'full_name',
        'congregation',
        'event_type',
        'event_date',
        'scanned_at',
    ];

    protected $casts = [
        'event_date' => 'date',
        'scanned_at' => 'datetime',
    ];

    public function member()
    {
        return $this->belongsTo(Member::class);
    }
}
