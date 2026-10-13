<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Pembayaran extends Model
{
    protected $primaryKey = 'id_pembayaran';

    protected $guarded = [];

    protected $casts = ['waktu_bayar' => 'datetime', 'midtrans_payload' => 'array', 'total_bayar' => 'decimal:2', 'komisi_platform' => 'decimal:2', 'pendapatan_mitra' => 'decimal:2', 'pendapatan_pelayan' => 'decimal:2'];

    public function booking()
    {
        return $this->belongsTo(Booking::class, 'id_booking');
    }
}
