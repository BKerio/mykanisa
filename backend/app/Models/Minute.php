<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Minute extends Model
{
    use HasFactory;

    protected $fillable = [
        'meeting_type',
        'meeting_date',
        'minute_number',
        'agenda_title_filter',
        'content',
        'agendas_json',
        'agenda_details_json',
        'created_by_user_id',
        'congregation',
    ];

    protected $casts = [
        'meeting_date' => 'date',
    ];

    public function attendees()
    {
        return $this->belongsToMany(Member::class, 'minute_attendees')
            ->withPivot('status')
            ->withTimestamps();
    }
}



