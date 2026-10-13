<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Layanan extends Model
{
    use HasFactory;

    protected $guarded = [];

    protected $casts = ['price' => 'decimal:2', 'is_active' => 'boolean'];

    public function mitra()
    {
        return $this->belongsTo(Mitra::class);
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class);
    }
}
