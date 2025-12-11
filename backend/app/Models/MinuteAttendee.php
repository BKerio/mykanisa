<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MinuteAttendee extends Model
{
    use HasFactory;

    protected $fillable = [
        'minute_id',
        'member_id',
        'status',
    ];

    // Relationships
    public function minute()
    {
        return $this->belongsTo(Minute::class);
    }

    public function member()
    {
        return $this->belongsTo(Member::class);
    }
}
