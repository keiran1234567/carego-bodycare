<?php

namespace App\Repositories\Eloquent;

use App\Models\Booking;
use App\Repositories\Contracts\BookingRepositoryInterface;

class BookingRepository implements BookingRepositoryInterface
{
    private array $with = ['user', 'mitra', 'pelayan.user', 'layanan', 'pembayaran', 'review', 'riwayats', 'voucher'];

    public function create(array $data): Booking
    {
        return Booking::create($data);
    }

    public function detailed(Booking $booking): Booking
    {
        return $booking->load($this->with);
    }

    public function forUser(int $id)
    {
        return Booking::with($this->with)->where('user_id', $id)->latest()->paginate();
    }

    public function forMitra(int $id)
    {
        return Booking::with($this->with)
            ->where('mitra_id', $id)
            ->where('status', '!=', Booking::MENUNGGU_PEMBAYARAN)
            ->latest()
            ->paginate();
    }

    public function forPelayan(int $id)
    {
        return Booking::with($this->with)
            ->where('pelayan_id', $id)
            ->whereIn('status', [
                Booking::DIKIRIM_KE_PELAYAN,
                Booking::DITERIMA_PELAYAN,
                Booking::DITOLAK_PELAYAN,
                Booking::MENUJU_LOKASI,
                Booking::SEDANG_DIKERJAKAN,
                Booking::SELESAI,
            ])
            ->orderByRaw("CASE status
                WHEN 'DIKIRIM_KE_PELAYAN' THEN 0
                WHEN 'DITERIMA_PELAYAN' THEN 1
                WHEN 'MENUJU_LOKASI' THEN 2
                WHEN 'SEDANG_DIKERJAKAN' THEN 3
                WHEN 'SELESAI' THEN 4
                ELSE 5
            END")
            ->orderBy('scheduled_at')
            ->paginate();
    }

    public function forAdmin()
    {
        return Booking::with($this->with)->latest()->paginate();
    }
}
