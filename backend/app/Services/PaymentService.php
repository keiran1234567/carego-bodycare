<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Pembayaran;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Throwable;

class PaymentService
{
    public function __construct(private BookingService $bookings) {}

    private function configure(): void
    {
        \Midtrans\Config::$serverKey = config('midtrans.server_key');
        \Midtrans\Config::$isProduction = config('midtrans.is_production');
        \Midtrans\Config::$isSanitized = true;
        \Midtrans\Config::$is3ds = true;
        \Midtrans\Config::$curlOptions = [
            CURLOPT_HTTPHEADER => [],
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_TIMEOUT => 15,
            CURLOPT_PROXY => '',
            CURLOPT_NOPROXY => '*',
        ];
    }

    public function create(Booking $booking): Pembayaran
    {
        if ($booking->status !== Booking::MENUNGGU_PEMBAYARAN) {
            throw ValidationException::withMessages(['booking' => 'Booking tidak menunggu pembayaran.']);
        }
        $existing = $booking->pembayaran;
        if ($existing?->status_pembayaran === 'PENDING' && $existing->midtrans_redirect_url) {
            return $existing->fresh('booking')->setAttribute('redirect_url', $existing->midtrans_redirect_url);
        }

        $order = 'CAREGO-'.$booking->id.'-'.now()->timestamp;
        $token = 'sandbox-'.$order;
        $redirectUrl = null;
        $fallbackToSandbox = ! config('midtrans.server_key');
        if (config('midtrans.server_key')) {
            $this->configure();
            try {
                $transaction = \Midtrans\Snap::createTransaction(['transaction_details' => ['order_id' => $order, 'gross_amount' => (int) $booking->total_price], 'customer_details' => ['first_name' => $booking->user->name, 'email' => $booking->user->email, 'phone' => $booking->user->phone]]);
            } catch (Throwable $error) {
                report($error);
                if (config('midtrans.allow_local_fallback') && ! config('midtrans.is_production') && app()->environment('local')) {
                    $fallbackToSandbox = true;
                } else {
                    throw ValidationException::withMessages(['payment' => 'Midtrans sedang tidak dapat dihubungi. Periksa koneksi internet server lalu coba lagi.']);
                }
            }
            if (! $fallbackToSandbox) {
                $token = $transaction->token;
                $redirectUrl = $transaction->redirect_url;
            }
        }

        $payment = Pembayaran::updateOrCreate(['id_booking' => $booking->id], ['midtrans_order_id' => $order, 'snap_token' => $token, 'midtrans_redirect_url' => $redirectUrl, 'total_bayar' => $booking->total_price, 'status_pembayaran' => 'PENDING']);

        if ($fallbackToSandbox) {
            $total = (float) $payment->total_bayar;
            $payment->update([
                'metode_pembayaran' => 'sandbox',
                'status_pembayaran' => 'PAID',
                'komisi_platform' => $total * .10,
                'pendapatan_mitra' => $total * .30,
                'pendapatan_pelayan' => $total * .60,
                'waktu_bayar' => now(),
                'midtrans_payload' => [
                    'transaction_status' => 'settlement',
                    'payment_type' => 'sandbox',
                    'fallback' => true,
                ],
            ]);
            if ($booking->status === Booking::MENUNGGU_PEMBAYARAN) {
                $booking->update(['status' => Booking::MENUNGGU_KONFIRMASI_MITRA]);
                $message = config('midtrans.server_key')
                    ? 'Pembayaran sandbox lokal berhasil. Midtrans sedang tidak dapat dihubungi, booking tetap dilanjutkan untuk pengujian.'
                    : 'Pembayaran sandbox berhasil. Menunggu konfirmasi mitra.';
                $this->bookings->record($booking->fresh(), null, $message);
            }
        }

        return $payment->fresh('booking')->setAttribute('redirect_url', $redirectUrl);
    }

    public function callback(array $payload): Pembayaran
    {
        $payment = Pembayaran::where('midtrans_order_id', $payload['order_id'] ?? '')->firstOrFail();
        $signature = hash('sha512', ($payload['order_id'] ?? '').($payload['status_code'] ?? '').($payload['gross_amount'] ?? '').config('midtrans.server_key'));
        if (config('midtrans.server_key') && ! hash_equals($signature, $payload['signature_key'] ?? '')) {
            throw ValidationException::withMessages(['signature' => 'Signature Midtrans tidak valid.']);
        }

        return $this->applyStatus($payment, $payload);
    }

    public function sync(Booking $booking): Pembayaran
    {
        $payment = $booking->pembayaran()->firstOrFail();
        if ($payment->status_pembayaran === 'PAID') {
            return $payment->fresh('booking');
        }

        $this->configure();
        try {
            $status = \Midtrans\Transaction::status($payment->midtrans_order_id);
        } catch (Throwable $error) {
            report($error);
            throw ValidationException::withMessages(['payment' => 'Status Midtrans belum dapat diperiksa. Coba lagi beberapa saat.']);
        }

        return $this->applyStatus($payment, json_decode(json_encode($status), true));
    }

    private function applyStatus(Pembayaran $payment, array $payload): Pembayaran
    {
        return DB::transaction(function () use ($payment, $payload) {
            $paid = in_array($payload['transaction_status'] ?? '', ['settlement', 'capture'], true);
            $total = (float) $payment->total_bayar;
            $payment->update(['metode_pembayaran' => $payload['payment_type'] ?? null, 'status_pembayaran' => $paid ? 'PAID' : strtoupper($payload['transaction_status'] ?? 'PENDING'), 'komisi_platform' => $paid ? $total * .10 : 0, 'pendapatan_mitra' => $paid ? $total * .30 : 0, 'pendapatan_pelayan' => $paid ? $total * .60 : 0, 'waktu_bayar' => $paid ? now() : null, 'midtrans_payload' => $payload]);
            if ($paid && $payment->booking->status === Booking::MENUNGGU_PEMBAYARAN) {
                $payment->booking->update(['status' => Booking::MENUNGGU_KONFIRMASI_MITRA]);
                $this->bookings->record($payment->booking->fresh(), null, 'Pembayaran berhasil. Menunggu konfirmasi mitra.');
            }

            return $payment->fresh('booking');
        });
    }
}
