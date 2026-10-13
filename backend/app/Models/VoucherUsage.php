<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class VoucherUsage extends Model
{
    protected $guarded = [];

    protected $casts = ['discount_amount' => 'decimal:2'];

    public function voucher() { return $this->belongsTo(Voucher::class); }
    public function booking() { return $this->belongsTo(Booking::class); }
}
