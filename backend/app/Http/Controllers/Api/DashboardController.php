<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\Booking;
use App\Models\Layanan;
use App\Models\Mitra;
use App\Models\Pelayan;
use App\Models\Pembayaran;
use App\Models\User;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $r)
    {
        $u = $r->user();
        if ($u->isRole('ADMIN')) {
            $data = ['users' => User::count(), 'mitras' => Mitra::count(), 'pelayans' => Pelayan::count(), 'layanans' => Layanan::count(), 'bookings' => Booking::count(), 'revenue' => Pembayaran::where('status_pembayaran', 'PAID')->sum('komisi_platform')];
        } elseif ($u->isRole('MITRA')) {
            $base = Booking::where('mitra_id', $u->mitra->id);
            $data = ['bookings' => (clone $base)->count(), 'incoming' => (clone $base)->where('status', Booking::MENUNGGU_KONFIRMASI_MITRA)->count(), 'completed' => (clone $base)->where('status', Booking::SELESAI)->count(), 'income' => Pembayaran::whereHas('booking', fn ($q) => $q->where('mitra_id', $u->mitra->id))->where('status_pembayaran', 'PAID')->sum('pendapatan_mitra'), 'daily_bookings' => $this->dailyBookings($u->mitra->id), 'monthly_bookings' => $this->monthlyBookings($u->mitra->id), 'monthly_income' => $this->monthlyIncome('mitra_id', $u->mitra->id, 'pendapatan_mitra'), 'top_services' => $this->topServices($u->mitra->id)];
        } elseif ($u->isRole('PELAYAN')) {
            $income = Pembayaran::whereHas('booking', fn ($q) => $q->where('pelayan_id', $u->pelayan->id))->where('status_pembayaran', 'PAID');
            $data = ['tasks' => Booking::where('pelayan_id', $u->pelayan->id)->count(), 'incoming' => Booking::where('pelayan_id', $u->pelayan->id)->where('status', Booking::DIKIRIM_KE_PELAYAN)->count(), 'completed' => Booking::where('pelayan_id', $u->pelayan->id)->where('status', Booking::SELESAI)->count(), 'income' => (clone $income)->sum('pendapatan_pelayan'), 'income_today' => (clone $income)->whereDate('waktu_bayar', today())->sum('pendapatan_pelayan'), 'income_week' => (clone $income)->whereBetween('waktu_bayar', [now()->startOfWeek(), now()->endOfWeek()])->sum('pendapatan_pelayan'), 'income_month' => (clone $income)->whereYear('waktu_bayar', now()->year)->whereMonth('waktu_bayar', now()->month)->sum('pendapatan_pelayan')];
        } else {
            $data = ['bookings' => Booking::where('user_id', $u->id)->count(), 'active' => Booking::where('user_id', $u->id)->whereNotIn('status', [Booking::SELESAI, Booking::DIBATALKAN])->count(), 'completed' => Booking::where('user_id', $u->id)->where('status', Booking::SELESAI)->count()];
        }

        return ApiResponse::success($data);
    }

    private function dailyBookings(int $mitraId) { return collect(range(6, 0))->map(fn ($d) => ['date' => now()->subDays($d)->format('d M'), 'total' => Booking::where('mitra_id', $mitraId)->whereDate('created_at', now()->subDays($d))->count()]); }
    private function monthlyBookings(int $mitraId) { return collect(range(5, 0))->map(fn ($m) => ['month' => now()->subMonths($m)->format('M'), 'total' => Booking::where('mitra_id', $mitraId)->whereYear('created_at', now()->subMonths($m)->year)->whereMonth('created_at', now()->subMonths($m)->month)->count()]); }
    private function monthlyIncome(string $field, int $id, string $amount) { return collect(range(5, 0))->map(fn ($m) => ['month' => now()->subMonths($m)->format('M'), 'total' => Pembayaran::whereHas('booking', fn ($q) => $q->where($field, $id))->where('status_pembayaran', 'PAID')->whereYear('waktu_bayar', now()->subMonths($m)->year)->whereMonth('waktu_bayar', now()->subMonths($m)->month)->sum($amount)]); }
    private function topServices(int $mitraId) { return Booking::selectRaw('layanan_id, count(*) total')->with('layanan:id,name')->where('mitra_id', $mitraId)->groupBy('layanan_id')->orderByDesc('total')->limit(5)->get(); }

    public function income(Request $r)
    {
        $field = $r->user()->isRole('MITRA') ? 'pendapatan_mitra' : 'pendapatan_pelayan';
        $relation = $r->user()->isRole('MITRA') ? ['mitra_id', $r->user()->mitra->id] : ['pelayan_id', $r->user()->pelayan->id];

        $payments = Pembayaran::with('booking.layanan')
            ->whereHas('booking', fn ($q) => $q->where($relation[0], $relation[1]))
            ->where('status_pembayaran', 'PAID')
            ->latest('waktu_bayar')
            ->get();

        return ApiResponse::success([
            'total' => $payments->sum($field),
            'transactions' => $payments->map(fn ($payment) => [
                'id' => $payment->id_pembayaran,
                'booking_id' => $payment->id_booking,
                'service' => $payment->booking?->layanan?->name,
                'amount' => $payment->{$field},
                'paid_at' => $payment->waktu_bayar,
                'method' => $payment->metode_pembayaran,
            ]),
        ]);
    }
}
