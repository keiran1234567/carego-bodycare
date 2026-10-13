<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WalletTransaction extends Model
{
    protected $guarded = [];
    protected $casts = ['amount' => 'decimal:2'];

    public function booking() { return $this->belongsTo(Booking::class); }
}
