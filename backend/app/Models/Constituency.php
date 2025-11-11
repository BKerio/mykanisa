<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Constituency extends Model
{
    use HasFactory;
    
    protected $fillable = ['county_id', 'constituency_name'];

    public function county()
    {
        return $this->belongsTo(County::class);
    }
}
