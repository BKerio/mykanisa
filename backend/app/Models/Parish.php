<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Parish extends Model
{
    use HasFactory;

    protected $fillable = [
        'presbytery_id',
        'name',
    ];

    public function presbytery()
    {
        return $this->belongsTo(Presbytery::class);
    }
}


