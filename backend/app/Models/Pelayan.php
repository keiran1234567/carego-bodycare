<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pelayan extends Model
{
    use HasFactory;

    protected $guarded = [];

    protected $casts = ['is_available' => 'boolean', 'rating' => 'decimal:2'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function mitra()
    {
        return $this->belongsTo(Mitra::class);
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class);
    }

    public function portofolios()
    {
        return $this->hasMany(Portofolio::class);
    }

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }
}
