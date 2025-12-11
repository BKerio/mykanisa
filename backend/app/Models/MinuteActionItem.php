<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MinuteActionItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'minute_id',
        'description',
        'responsible_member_id',
        'due_date',
        'status',
        'status_reason'
    ];

    protected $casts = [
        'due_date' => 'date',
    ];

    // Relationships
    public function minute()
    {
        return $this->belongsTo(Minute::class);
    }

    public function responsibleMember()
    {
        return $this->belongsTo(Member::class, 'responsible_member_id');
    }
}
