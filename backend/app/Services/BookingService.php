<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Layanan;
use App\Models\Notifikasi;
use App\Models\Riwayat;
use App\Models\User;
use App\Models\Voucher;
use App\Models\VoucherUsage;
use App\Models\WalletTransaction;
use App\Repositories\Contracts\BookingRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class BookingService
{
    public function __construct(private BookingRepositoryInterface $repository) {}

    public function create(User $user, array $data): Booking
    {
        return DB::transaction(function () use ($user, $data) {
            $layanan = Layanan::findOrFail($data['layanan_id']);
            if ($layanan->mitra_id != (int) $data['mitra_id']) {
                throw ValidationException::withMessages(['layanan_id' => 'Layanan tidak dimiliki mitra tersebut.']);
            }
            $pelayan = \App\Models\Pelayan::findOrFail($data['pelayan_id']);
            if ($pelayan->mitra_id != (int) $data['mitra_id']) {
                throw ValidationException::withMessages(['pelayan_id' => 'Pelayan tidak bekerja pada mitra tersebut.']);
            }
            $scheduled = \Carbon\Carbon::parse($data['scheduled_at']);
            $duration = max(1, (int) $layanan->duration_minutes);
            $conflict = Booking::where('pelayan_id', $pelayan->id)
                ->whereNotIn('status', [Booking::DITOLAK_MITRA, Booking::DITOLAK_PELAYAN, Booking::DIBATALKAN, Booking::SELESAI])
                ->whereBetween('scheduled_at', [$scheduled->copy()->subMinutes($duration - 1), $scheduled->copy()->addMinutes($duration - 1)])
                ->exists();
            if ($conflict) {
                throw ValidationException::withMessages(['scheduled_at' => 'Jadwal pelayan sudah terisi. Pilih waktu lain.']);
            }
            $distance = (float) ($data['travel_distance_km'] ?? 0);
            if ($distance > 8) {
                throw ValidationException::withMessages(['travel_distance_km' => 'Jarak maksimal layanan adalah 8 KM.']);
            }
            $travelFee = $distance > 5 ? 15000 : 10000;
            $voucher = null;
            $discount = 0;
            if (! empty($data['voucher_code'])) {
                $voucher = Voucher::where('code', strtoupper($data['voucher_code']))->lockForUpdate()->first();
                if (! $voucher) {
                    throw ValidationException::withMessages(['voucher_code' => 'Kode voucher tidak ditemukan.']);
                }
                if (! $voucher->is_active || ($voucher->starts_at && $voucher->starts_at->isFuture()) || ($voucher->expires_at && $voucher->expires_at->isPast()) || ($voucher->quota !== null && $voucher->used_count >= $voucher->quota)) {
                    throw ValidationException::withMessages(['voucher_code' => 'Voucher tidak aktif, kedaluwarsa, atau kuotanya habis.']);
                }
                if ((float) $layanan->price < (float) $voucher->min_transaction) {
                    throw ValidationException::withMessages(['voucher_code' => 'Minimum transaksi voucher belum terpenuhi.']);
                }
                $discount = $voucher->discount_type === 'PERCENT'
                    ? (float) $layanan->price * ((float) $voucher->discount_value / 100)
                    : (float) $voucher->discount_value;
                if ($voucher->max_discount !== null) $discount = min($discount, (float) $voucher->max_discount);
                $discount = min($discount, max(0, (float) $layanan->price - 1000));
            }
            unset($data['voucher_code']);
            $booking = $this->repository->create([...$data, 'user_id' => $user->id, 'booking_code' => 'CG-'.now()->format('YmdHis').'-'.random_int(100, 999), 'subtotal' => $layanan->price, 'travel_fee' => $travelFee, 'discount_amount' => $discount, 'voucher_id' => $voucher?->id, 'total_price' => (float) $layanan->price + $travelFee - $discount, 'status' => Booking::MENUNGGU_PEMBAYARAN]);
            if ($voucher) {
                $voucher->increment('used_count');
                VoucherUsage::create(['voucher_id' => $voucher->id, 'user_id' => $user->id, 'booking_id' => $booking->id, 'discount_amount' => $discount]);
            }
            $this->record($booking, $user, 'Booking berhasil dibuat.');

            return $this->repository->detailed($booking);
        });
    }

    public function transition(Booking $booking, string $status, User $actor, ?string $reason = null): Booking
    {
        if ($status === Booking::DIBATALKAN) {
            abort_unless(
                ($actor->isRole('USER') && $booking->user_id === $actor->id)
                || ($actor->isRole('MITRA') && $booking->mitra?->user_id === $actor->id)
                || $actor->isRole('ADMIN'),
                403,
                'Booking hanya dapat dibatalkan oleh pelanggan atau Mitra terkait.'
            );
            if (! in_array($booking->status, [
                Booking::MENUNGGU_PEMBAYARAN,
                Booking::MENUNGGU_KONFIRMASI_MITRA,
                Booking::DITERIMA_MITRA,
                Booking::DIKIRIM_KE_PELAYAN,
                Booking::DITERIMA_PELAYAN,
            ], true)) {
                throw ValidationException::withMessages(['status' => 'Booking pada tahap ini tidak dapat dibatalkan.']);
            }
            $booking->update(['status' => $status, 'rejection_reason' => $reason]);
            if ($actor->isRole('MITRA') || $actor->isRole('ADMIN')) {
                $this->refund($booking, 'Refund karena pesanan dibatalkan Mitra.');
            }
            $this->record($booking, $actor, $reason ?: 'Booking dibatalkan.');

            return $this->repository->detailed($booking->fresh());
        }

        $allowed = [
            Booking::MENUNGGU_KONFIRMASI_MITRA => [Booking::DITERIMA_MITRA, Booking::DITOLAK_MITRA],
            Booking::DITERIMA_MITRA => [Booking::DIKIRIM_KE_PELAYAN],
            Booking::DIKIRIM_KE_PELAYAN => [Booking::DITERIMA_PELAYAN, Booking::DITOLAK_PELAYAN],
            Booking::DITERIMA_PELAYAN => [Booking::MENUJU_LOKASI],
            Booking::MENUJU_LOKASI => [Booking::SEDANG_DIKERJAKAN],
            Booking::SEDANG_DIKERJAKAN => [Booking::SELESAI],
        ];
        if (! in_array($status, $allowed[$booking->status] ?? [], true)) {
            throw ValidationException::withMessages(['status' => "Transisi {$booking->status} ke {$status} tidak diizinkan."]);
        }
        $mitraStatuses = [Booking::DITERIMA_MITRA, Booking::DITOLAK_MITRA, Booking::DIKIRIM_KE_PELAYAN];
        $pelayanStatuses = [Booking::DITERIMA_PELAYAN, Booking::DITOLAK_PELAYAN, Booking::MENUJU_LOKASI, Booking::SEDANG_DIKERJAKAN, Booking::SELESAI];
        abort_if(in_array($status, $mitraStatuses, true) && ! $actor->isRole('MITRA') && ! $actor->isRole('ADMIN'), 403, 'Status ini hanya dapat diperbarui oleh Mitra.');
        abort_if(in_array($status, $pelayanStatuses, true) && ! $actor->isRole('PELAYAN') && ! $actor->isRole('ADMIN'), 403, 'Status ini hanya dapat diperbarui oleh Pelayan.');
        $booking->update(['status' => $status, 'rejection_reason' => $reason]);
        if ($status === Booking::DITOLAK_MITRA) {
            $this->refund($booking, 'Refund karena pesanan dibatalkan Mitra.');
        }
        $this->record($booking, $actor, $reason ?: str_replace('_', ' ', ucwords(strtolower($status), '_')));

        return $this->repository->detailed($booking->fresh());
    }

    private function refund(Booking $booking, string $description): void
    {
        $payment = $booking->pembayaran;
        if (! $payment || $payment->status_pembayaran !== 'PAID') return;
        if (WalletTransaction::where('booking_id', $booking->id)->where('type', 'REFUND')->exists()) return;
        $amount = (float) $payment->total_bayar;
        $booking->user()->increment('wallet_balance', $amount);
        WalletTransaction::create(['user_id' => $booking->user_id, 'booking_id' => $booking->id, 'type' => 'REFUND', 'amount' => $amount, 'description' => $description]);
        $payment->update(['status_pembayaran' => 'REFUNDED', 'komisi_platform' => 0, 'pendapatan_mitra' => 0, 'pendapatan_pelayan' => 0]);
    }

    public function record(Booking $booking, ?User $actor, string $description): void
    {
        Riwayat::create(['booking_id' => $booking->id, 'status' => $booking->status, 'description' => $description, 'changed_by' => $actor?->id]);
        foreach (array_filter([$booking->user_id, $booking->mitra->user_id, $booking->pelayan->user_id]) as $id) {
            Notifikasi::create(['user_id' => $id, 'booking_id' => $booking->id, 'type' => 'BOOKING', 'title' => 'Status Booking Diperbarui', 'message' => $description, 'data' => ['status' => $booking->status]]);
        }
    }
}
