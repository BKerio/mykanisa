<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Dependency extends Model
{
    use HasFactory;

    protected $fillable = [
        'member_id',
        'name',
        'year_of_birth',
        'birth_cert_number',
        'is_baptized',
        'takes_holy_communion',
        'school',
        'image',
    ];

    protected $casts = [
        'is_baptized' => 'boolean',
        'takes_holy_communion' => 'boolean',
    ];

    public function member()
    {
        return $this->belongsTo(Member::class);
    }
}
