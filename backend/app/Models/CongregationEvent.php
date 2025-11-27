<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CongregationEvent extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'location',
        'event_date',
        'start_time',
        'end_time',
        'is_all_day',
        'congregation',
        'created_by',
        'sms_sent_count',
    ];

    protected $casts = [
        'event_date' => 'date',
        'is_all_day' => 'boolean',
        'sms_sent_count' => 'integer',
    ];

    /**
     * Get the elder who created this event
     */
    public function creator()
    {
        return $this->belongsTo(Member::class, 'created_by');
    }
}
