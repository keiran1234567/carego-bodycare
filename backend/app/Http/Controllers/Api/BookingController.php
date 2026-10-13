<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreBookingRequest;
use App\Http\Responses\ApiResponse;
use App\Models\Booking;
use App\Models\User;
use App\Repositories\Contracts\BookingRepositoryInterface;
use App\Services\BookingService;
use Illuminate\Http\Request;

class BookingController extends Controller
{
    public function __construct(private BookingRepositoryInterface $repository, private BookingService $service) {}

    public function index(Request $r)
    {
        $u = $r->user();
        $data = $u->isRole('ADMIN')
            ? $this->repository->forAdmin()
            : ($u->isRole('MITRA')
                ? $this->repository->forMitra($u->mitra->id)
                : ($u->isRole('PELAYAN')
                    ? $this->repository->forPelayan($u->pelayan->id)
                    : $this->repository->forUser($u->id)));

        return ApiResponse::success($data);
    }

    public function store(StoreBookingRequest $r)
    {
        return ApiResponse::success($this->service->create($r->user(), $r->validated()), 'Booking dibuat.', 201);
    }

    public function show(Booking $booking)
    {
        $this->authorizeBooking(request(), $booking);
        return ApiResponse::success($this->repository->detailed($booking));
    }

    public function history(Request $request, Booking $booking)
    {
        $this->authorizeBooking($request, $booking);

        return ApiResponse::success($booking->riwayats()->with('actor')->oldest()->get());
    }

    public function updateStatus(Request $r, Booking $booking)
    {
        $this->authorizeBooking($r, $booking);
        $d = $r->validate(['status' => 'required|string', 'reason' => 'nullable|string|max:1000']);

        return ApiResponse::success($this->service->transition($booking, $d['status'], $r->user(), $d['reason'] ?? null), 'Status booking diperbarui.');
    }

    public function destroy(Request $r, Booking $booking)
    {
        if ($booking->user_id !== $r->user()->id) {
            return ApiResponse::error('Tidak diizinkan.', null, 403);
        }

        return ApiResponse::success(
            $this->service->transition($booking, Booking::DIBATALKAN, $r->user(), 'Dibatalkan oleh pelanggan.'),
            'Booking dibatalkan.'
        );
    }

    public function adminStore(Request $request)
    {
        $data = $request->validate([
            'user_id' => 'required|exists:users,id',
            'mitra_id' => 'required|exists:mitras,id',
            'pelayan_id' => 'required|exists:pelayans,id',
            'layanan_id' => 'required|exists:layanans,id',
            'scheduled_at' => 'required|date|after:now',
            'service_address' => 'required|string|max:1000',
            'travel_distance_km' => 'nullable|numeric|min:0|max:8',
            'notes' => 'nullable|string|max:1000',
            'voucher_code' => 'nullable|string|max:50',
        ]);
        $user = User::where('role', 'USER')->findOrFail($data['user_id']);
        unset($data['user_id']);

        return ApiResponse::success(
            $this->service->create($user, $data),
            'Booking dibuat oleh Admin.',
            201
        );
    }

    public function adminDestroy(Booking $booking)
    {
        $booking->delete();

        return ApiResponse::success(null, 'Booking dihapus oleh Admin.');
    }

    private function authorizeBooking(Request $request, Booking $booking): void
    {
        $user = $request->user();
        $allowed = $user->isRole('ADMIN')
            || ($user->isRole('USER') && $booking->user_id === $user->id)
            || ($user->isRole('MITRA') && $booking->mitra_id === $user->mitra?->id)
            || ($user->isRole('PELAYAN') && $booking->pelayan_id === $user->pelayan?->id);
        abort_unless($allowed, 403, 'Tidak diizinkan mengakses booking ini.');
    }
}
