<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Mitra extends Model
{
    use HasFactory;

    protected $guarded = [];

    protected $casts = [
        'is_verified' => 'boolean',
        'rating' => 'decimal:2',
        'verified_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function pelayans()
    {
        return $this->hasMany(Pelayan::class);
    }

    public function layanans()
    {
        return $this->hasMany(Layanan::class);
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class);
    }
}
