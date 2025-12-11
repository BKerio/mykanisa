<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AuditLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'user_type',
        'action',
        'model_type',
        'model_id',
        'description',
        'details',
        'ip_address',
        'user_agent',
    ];

    protected $casts = [
        'details' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function user()
    {
        return $this->morphTo();
    }
    
    // Helper to get formatted date
    public function getFormattedDateAttribute()
    {
        return $this->created_at->format('Y-m-d H:i:s');
    }
}
