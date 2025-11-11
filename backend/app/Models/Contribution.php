<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Contribution extends Model
{
    use HasFactory;

    protected $fillable = [
        'member_id',
        'payment_id',
        'contribution_type',
        'amount',
        'description',
        'contribution_date',
        'payment_method',
        'reference_number',
        'status',
        'notes',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'contribution_date' => 'datetime',
    ];

    // Relationships
    public function member()
    {
        return $this->belongsTo(Member::class);
    }

    public function payment()
    {
        return $this->belongsTo(Payment::class);
    }

    // Scopes
    public function scopeByAccountType($query, $accountType)
    {
        return $query->where('contribution_type', $accountType);
    }

    public function scopeByMember($query, $memberId)
    {
        return $query->where('member_id', $memberId);
    }

    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }

    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('contribution_date', [$startDate, $endDate]);
    }

    // Static methods for summary calculations
    public static function getMemberSummary($memberId, $startDate = null, $endDate = null)
    {
        $query = self::where('member_id', $memberId)
            ->where('status', 'completed');

        if ($startDate && $endDate) {
            $query->whereBetween('contribution_date', [$startDate, $endDate]);
        }

        return $query->selectRaw('
            contribution_type,
            SUM(amount) as total_amount,
            COUNT(*) as contribution_count
        ')
        ->groupBy('contribution_type')
        ->get();
    }

    public static function getTotalByAccountType($accountType, $startDate = null, $endDate = null)
    {
        $query = self::where('contribution_type', $accountType)
            ->where('status', 'completed');

        if ($startDate && $endDate) {
            $query->whereBetween('contribution_date', [$startDate, $endDate]);
        }

        return $query->sum('amount');
    }

    public static function getMemberTotalContributions($memberId, $startDate = null, $endDate = null)
    {
        $query = self::where('member_id', $memberId)
            ->where('status', 'completed');

        if ($startDate && $endDate) {
            $query->whereBetween('contribution_date', [$startDate, $endDate]);
        }

        return $query->sum('amount');
    }
}