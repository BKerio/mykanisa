<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Presbytery extends Model
{
    use HasFactory;

    protected $fillable = [
        'region_id',
        'name',
    ];

    public function region()
    {
        return $this->belongsTo(Region::class);
    }

    public function parishes()
    {
        return $this->hasMany(Parish::class);
    }
}


