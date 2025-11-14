<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Announcement extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'message',
        'type',
        'sent_by',
        'recipient_id',
        'reply_to',
        'is_priority',
        'target_count',
        'read_at',
        'deleted_by_member_at',
        'deleted_by_member_id',
    ];

    protected $casts = [
        'is_priority' => 'boolean',
        'read_at' => 'datetime',
        'deleted_by_member_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Get the sender (elder/leader) of this announcement
     */
    public function sender()
    {
        return $this->belongsTo(Member::class, 'sent_by');
    }

    /**
     * Get the recipient (for individual messages)
     */
    public function recipient()
    {
        return $this->belongsTo(Member::class, 'recipient_id');
    }

    /**
     * Get the original announcement this is a reply to
     */
    public function originalAnnouncement()
    {
        return $this->belongsTo(Announcement::class, 'reply_to');
    }

    /**
     * Get all replies to this announcement
     */
    public function replies()
    {
        return $this->hasMany(Announcement::class, 'reply_to')->orderBy('created_at', 'asc');
    }

    /**
     * Get the member who deleted this announcement
     */
    public function deletedByMember()
    {
        return $this->belongsTo(Member::class, 'deleted_by_member_id');
    }

    /**
     * Check if announcement is deleted by a specific member
     */
    public function isDeletedByMember($memberId)
    {
        return $this->deleted_by_member_id == $memberId && $this->deleted_by_member_at !== null;
    }

    /**
     * Mark announcement as deleted by a member
     */
    public function markAsDeletedByMember($memberId)
    {
        $this->update([
            'deleted_by_member_id' => $memberId,
            'deleted_by_member_at' => now(),
        ]);
    }

    /**
     * Restore announcement for a member (undo deletion)
     */
    public function restoreForMember()
    {
        $this->update([
            'deleted_by_member_id' => null,
            'deleted_by_member_at' => null,
        ]);
    }

    /**
     * Get all members who have read this announcement
     */
    public function readers()
    {
        return $this->belongsToMany(Member::class, 'announcement_reads')
            ->withPivot('read_at')
            ->withTimestamps();
    }

    /**
     * Check if a member has read this announcement
     */
    public function isReadBy($memberId)
    {
        return $this->readers()->where('member_id', $memberId)->exists();
    }

    /**
     * Mark announcement as read by a member
     */
    public function markAsReadBy($memberId)
    {
        $this->readers()->syncWithoutDetaching([
            $memberId => ['read_at' => now()]
        ]);
    }

    /**
     * Scope for broadcast announcements
     */
    public function scopeBroadcast($query)
    {
        return $query->where('type', 'broadcast');
    }

    /**
     * Scope for individual announcements
     */
    public function scopeIndividual($query)
    {
        return $query->where('type', 'individual');
    }

    /**
     * Scope for priority announcements
     */
    public function scopePriority($query)
    {
        return $query->where('is_priority', true);
    }

    /**
     * Scope for unread announcements for a member
     */
    public function scopeUnreadFor($query, $memberId)
    {
        return $query->whereDoesntHave('readers', function($q) use ($memberId) {
            $q->where('member_id', $memberId);
        });
    }
}

