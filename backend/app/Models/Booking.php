<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Booking extends Model
{
    use HasFactory;

    const MENUNGGU_PEMBAYARAN = 'MENUNGGU_PEMBAYARAN';

    const MENUNGGU_KONFIRMASI_MITRA = 'MENUNGGU_KONFIRMASI_MITRA';

    const DITERIMA_MITRA = 'DITERIMA_MITRA';

    const DITOLAK_MITRA = 'DITOLAK_MITRA';

    const DIKIRIM_KE_PELAYAN = 'DIKIRIM_KE_PELAYAN';

    const DITERIMA_PELAYAN = 'DITERIMA_PELAYAN';

    const DITOLAK_PELAYAN = 'DITOLAK_PELAYAN';

    const MENUJU_LOKASI = 'MENUJU_LOKASI';

    const SEDANG_DIKERJAKAN = 'SEDANG_DIKERJAKAN';

    const SELESAI = 'SELESAI';

    const DIBATALKAN = 'DIBATALKAN';

    protected $guarded = [];

    protected $casts = ['scheduled_at' => 'datetime', 'subtotal' => 'decimal:2', 'discount_amount' => 'decimal:2', 'travel_fee' => 'decimal:2', 'travel_distance_km' => 'decimal:2', 'total_price' => 'decimal:2'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function mitra()
    {
        return $this->belongsTo(Mitra::class);
    }

    public function pelayan()
    {
        return $this->belongsTo(Pelayan::class);
    }

    public function layanan()
    {
        return $this->belongsTo(Layanan::class);
    }

    public function pembayaran()
    {
        return $this->hasOne(Pembayaran::class, 'id_booking');
    }

    public function review()
    {
        return $this->hasOne(Review::class);
    }

    public function riwayats()
    {
        return $this->hasMany(Riwayat::class);
    }

    public function chats()
    {
        return $this->hasMany(Chat::class);
    }

    public function voucher() { return $this->belongsTo(Voucher::class); }
    public function voucherUsage() { return $this->hasOne(VoucherUsage::class); }
}
