<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ChatOnlineStatus extends Model
{
    use HasFactory;

    protected $table = 'chat_online_status';

    protected $fillable = [
        'member_id',
        'is_online',
        'last_seen',
        'socket_id',
    ];

    protected $casts = [
        'is_online' => 'boolean',
        'last_seen' => 'datetime',
    ];

    /**
     * Get the member this status belongs to
     */
    public function member()
    {
        return $this->belongsTo(Member::class);
    }

    /**
     * Mark member as online
     */
    public static function markOnline($memberId, $socketId = null)
    {
        return self::updateOrCreate(
            ['member_id' => $memberId],
            [
                'is_online' => true,
                'socket_id' => $socketId,
                'updated_at' => now(),
            ]
        );
    }

    /**
     * Mark member as offline
     */
    public static function markOffline($memberId)
    {
        return self::updateOrCreate(
            ['member_id' => $memberId],
            [
                'is_online' => false,
                'last_seen' => now(),
                'socket_id' => null,
                'updated_at' => now(),
            ]
        );
    }

    /**
     * Check if member is online
     */
    public static function isOnline($memberId)
    {
        $status = self::where('member_id', $memberId)->first();
        return $status ? $status->is_online : false;
    }

    /**
     * Get last seen time
     */
    public static function getLastSeen($memberId)
    {
        $status = self::where('member_id', $memberId)->first();
        return $status ? $status->last_seen : null;
    }

    /**
     * Scope for online members
     */
    public function scopeOnline($query)
    {
        return $query->where('is_online', true);
    }
}

