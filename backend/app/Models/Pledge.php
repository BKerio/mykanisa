<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pledge extends Model
{
    use HasFactory;

    protected $fillable = [
        'member_id',
        'account_type',
        'pledge_amount',
        'remaining_amount',
        'fulfilled_amount',
        'pledge_date',
        'target_date',
        'description',
        'status',
    ];

    protected $casts = [
        'pledge_amount' => 'decimal:2',
        'remaining_amount' => 'decimal:2',
        'fulfilled_amount' => 'decimal:2',
        'pledge_date' => 'date',
        'target_date' => 'date',
    ];

    /**
     * Get the member that made this pledge
     */
    public function member()
    {
        return $this->belongsTo(Member::class);
    }

    /**
     * Check if pledge is fulfilled
     */
    public function isFulfilled()
    {
        return $this->remaining_amount <= 0 || $this->status === 'fulfilled';
    }

    /**
     * Get fulfillment percentage
     */
    public function getFulfillmentPercentage()
    {
        if ($this->pledge_amount <= 0) {
            return 0;
        }
        return ($this->fulfilled_amount / $this->pledge_amount) * 100;
    }

    /**
     * Decrement remaining amount when contribution is made
     */
    public function decrementRemaining($amount)
    {
        $this->remaining_amount = max(0, $this->remaining_amount - $amount);
        $this->fulfilled_amount = min($this->pledge_amount, $this->fulfilled_amount + $amount);
        
        // Auto-update status if fulfilled
        if ($this->remaining_amount <= 0 && $this->status === 'active') {
            $this->status = 'fulfilled';
        }
        
        $this->save();
    }

    /**
     * Scope for active pledges
     */
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    /**
     * Scope for fulfilled pledges
     */
    public function scopeFulfilled($query)
    {
        return $query->where('status', 'fulfilled');
    }

    /**
     * Scope by account type
     */
    public function scopeByAccountType($query, $accountType)
    {
        return $query->where('account_type', $accountType);
    }

    /**
     * Scope by member
     */
    public function scopeByMember($query, $memberId)
    {
        return $query->where('member_id', $memberId);
    }
}

