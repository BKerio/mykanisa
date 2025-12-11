<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MinuteAgendaItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'minute_id',
        'title',
        'notes',
        'order',
        'attachments',
    ];

    protected $casts = [
        'attachments' => 'array',
    ];

    // Relationships
    public function minute()
    {
        return $this->belongsTo(Minute::class);
    }
}
