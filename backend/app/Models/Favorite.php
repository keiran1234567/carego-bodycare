<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Favorite extends Model
{
    protected $guarded = [];
    public function layanan() { return $this->belongsTo(Layanan::class); }
    public function mitra() { return $this->belongsTo(Mitra::class); }
}
