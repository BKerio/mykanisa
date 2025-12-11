<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Minute extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'meeting_date',
        'meeting_time',
        'meeting_type',
        'location',
        'is_online',
        'online_link',
        'notes',
        'summary',
        'created_by',
    ];

    protected $casts = [
        'meeting_date' => 'date',
        'meeting_time' => 'datetime:H:i',
        'is_online' => 'boolean',
    ];

    // Relationships
    public function creator()
    {
        return $this->belongsTo(Member::class, 'created_by');
    }

    public function attendees()
    {
        return $this->hasMany(MinuteAttendee::class);
    }

    public function agendaItems()
    {
        return $this->hasMany(MinuteAgendaItem::class)->orderBy('order');
    }

    public function actionItems()
    {
        return $this->hasMany(MinuteActionItem::class);
    }
}



