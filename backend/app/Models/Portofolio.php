<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Portofolio extends Model
{
    protected $guarded = [];

    public function pelayan()
    {
        return $this->belongsTo(Pelayan::class);
    }
}
