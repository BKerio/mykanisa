<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;

    protected $fillable = [
        'conversation_id',
        'sender_id',
        'sender_type',
        'message',
        'message_type',
        'attachment_url',
        'attachment_name',
        'is_read',
        'read_at',
    ];

    protected $casts = [
        'is_read' => 'boolean',
        'read_at' => 'datetime',
    ];

    /**
     * Get the conversation this message belongs to
     */
    public function conversation()
    {
        return $this->belongsTo(Conversation::class);
    }

    /**
     * Get the sender of this message
     */
    public function sender()
    {
        return $this->belongsTo(Member::class, 'sender_id');
    }

    /**
     * Scope for unread messages
     */
    public function scopeUnread($query)
    {
        return $query->where('is_read', false);
    }

    /**
     * Scope for messages by type
     */
    public function scopeByType($query, $type)
    {
        return $query->where('message_type', $type);
    }

    /**
     * Get formatted time for display
     */
    public function getFormattedTimeAttribute()
    {
        return $this->created_at->format('H:i');
    }

    /**
     * Get formatted date for display
     */
    public function getFormattedDateAttribute()
    {
        if ($this->created_at->isToday()) {
            return 'Today';
        } elseif ($this->created_at->isYesterday()) {
            return 'Yesterday';
        } else {
            return $this->created_at->format('M d, Y');
        }
    }
}

