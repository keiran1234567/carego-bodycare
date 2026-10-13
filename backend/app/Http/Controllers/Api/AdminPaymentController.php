<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\Booking;
use App\Models\Pembayaran;
use Illuminate\Http\Request;

class AdminPaymentController extends Controller
{
    public function index()
    {
        return ApiResponse::success(
            Pembayaran::with('booking.user', 'booking.layanan')
                ->latest('id_pembayaran')
                ->paginate()
        );
    }

    public function store(Request $request)
    {
        $data = $this->validated($request);
        $booking = Booking::findOrFail($data['id_booking']);
        $payment = Pembayaran::create($this->payload($data, $booking));

        return ApiResponse::success($payment->load('booking'), 'Pembayaran dibuat.', 201);
    }

    public function update(Request $request, Pembayaran $pembayaran)
    {
        $data = $this->validated($request, $pembayaran);
        $booking = Booking::findOrFail($data['id_booking']);
        $pembayaran->update($this->payload($data, $booking, $pembayaran));

        return ApiResponse::success($pembayaran->fresh('booking'), 'Pembayaran diperbarui.');
    }

    public function destroy(Pembayaran $pembayaran)
    {
        $pembayaran->delete();

        return ApiResponse::success(null, 'Pembayaran dihapus.');
    }

    private function validated(Request $request, ?Pembayaran $payment = null): array
    {
        return $request->validate([
            'id_booking' => 'required|exists:bookings,id|unique:pembayarans,id_booking,'.($payment?->id_pembayaran ?? 'NULL').',id_pembayaran',
            'metode_pembayaran' => 'nullable|string|max:100',
            'total_bayar' => 'nullable|numeric|min:0',
            'status_pembayaran' => 'required|in:PENDING,PAID,FAILED,EXPIRED,REFUNDED',
        ]);
    }

    private function payload(array $data, Booking $booking, ?Pembayaran $payment = null): array
    {
        $total = (float) ($data['total_bayar'] ?? $booking->total_price);
        $paid = $data['status_pembayaran'] === 'PAID';

        return [
            'id_booking' => $booking->id,
            'midtrans_order_id' => $payment?->midtrans_order_id
                ?? 'ADMIN-'.$booking->booking_code.'-'.now()->format('YmdHis'),
            'metode_pembayaran' => $data['metode_pembayaran'] ?? null,
            'total_bayar' => $total,
            'status_pembayaran' => $data['status_pembayaran'],
            'komisi_platform' => $paid ? $total * .10 : 0,
            'pendapatan_mitra' => $paid ? $total * .30 : 0,
            'pendapatan_pelayan' => $paid ? $total * .60 : 0,
            'waktu_bayar' => $paid ? ($payment?->waktu_bayar ?? now()) : null,
        ];
    }
}
