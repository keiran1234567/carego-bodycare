<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreChatRequest;
use App\Http\Requests\StoreReviewRequest;
use App\Http\Responses\ApiResponse;
use App\Models\Booking;
use App\Models\Chat;
use App\Models\Notifikasi;
use App\Models\Review;
use Illuminate\Http\Request;

class InteractionController extends Controller
{
    public function reviews()
    {
        return ApiResponse::success(Review::with('user', 'mitra', 'pelayan', 'booking')->latest()->paginate());
    }

    public function storeReview(StoreReviewRequest $r)
    {
        $b = Booking::findOrFail($r->booking_id);
        if ($b->user_id !== $r->user()->id || $b->status !== Booking::SELESAI) {
            return ApiResponse::error('Review hanya untuk booking selesai milik Anda.', null, 403);
        }
        $data = $r->validate(['booking_id' => 'required|exists:bookings,id', 'rating' => 'required|integer|min:1|max:5', 'mitra_rating' => 'nullable|integer|min:1|max:5', 'pelayan_rating' => 'nullable|integer|min:1|max:5', 'review' => 'nullable|string|max:2000', 'photo_urls' => 'nullable|array']);
        $review = Review::create([...$data, 'user_id' => $r->user()->id, 'mitra_id' => $b->mitra_id, 'pelayan_id' => $b->pelayan_id]);
        $b->mitra->update(['rating' => Review::where('mitra_id', $b->mitra_id)->avg('mitra_rating') ?: Review::where('mitra_id', $b->mitra_id)->avg('rating')]);
        $b->pelayan->update(['rating' => Review::where('pelayan_id', $b->pelayan_id)->avg('pelayan_rating') ?: Review::where('pelayan_id', $b->pelayan_id)->avg('rating')]);

        return ApiResponse::success($review, 'Review dikirim.', 201);
    }

    public function updateReview(Request $r, Review $review)
    {
        if ($review->user_id !== $r->user()->id && ! $r->user()->isRole('ADMIN')) {
            return ApiResponse::error('Tidak diizinkan.', null, 403);
        }
        $review->update($r->validate(['rating' => 'sometimes|integer|min:1|max:5', 'review' => 'nullable|string|max:2000', 'photo_urls' => 'nullable|array']));

        return ApiResponse::success($review, 'Review diperbarui.');
    }

    public function destroyReview(Request $r, Review $review)
    {
        if ($review->user_id !== $r->user()->id && ! $r->user()->isRole('ADMIN')) {
            return ApiResponse::error('Tidak diizinkan.', null, 403);
        }
        $review->delete();

        return ApiResponse::success(null, 'Review dihapus.');
    }

    public function chats(Request $r, Booking $booking)
    {
        $this->ensureChatAllowed($r, $booking);
        return ApiResponse::success($booking->chats()->with('sender', 'receiver')->latest()->paginate());
    }

    public function storeChat(StoreChatRequest $r)
    {
        $booking = Booking::findOrFail($r->booking_id);
        $this->ensureChatAllowed($r, $booking);
        $participants = array_filter([$booking->user_id, $booking->mitra?->user_id, $booking->pelayan?->user_id]);
        abort_unless(in_array((int) $r->receiver_id, $participants, true), 422, 'Penerima bukan peserta booking.');
        $chat = Chat::create([...$r->validated(), 'sender_id' => $r->user()->id]);

        return ApiResponse::success($chat->load('sender', 'receiver'), 'Pesan dikirim.', 201);
    }

    public function updateChat(Request $r, Chat $chat)
    {
        if ($chat->sender_id !== $r->user()->id) {
            return ApiResponse::error('Tidak diizinkan.', null, 403);
        }
        $chat->update($r->validate(['message' => 'required|string|max:3000']));

        return ApiResponse::success($chat, 'Pesan diperbarui.');
    }

    public function destroyChat(Request $r, Chat $chat)
    {
        if ($chat->sender_id !== $r->user()->id && ! $r->user()->isRole('ADMIN')) {
            return ApiResponse::error('Tidak diizinkan.', null, 403);
        }
        $chat->delete();

        return ApiResponse::success(null, 'Pesan dihapus.');
    }

    public function notifications(Request $r)
    {
        return ApiResponse::success($r->user()->notifications()->latest()->paginate());
    }

    public function read(Request $r, Notifikasi $notifikasi)
    {
        if ($notifikasi->user_id !== $r->user()->id) {
            return ApiResponse::error('Tidak diizinkan.', null, 403);
        }$notifikasi->update(['read_at' => now()]);

        return ApiResponse::success($notifikasi);
    }

    public function storeNotification(Request $r)
    {
        $data = $r->validate(['user_id' => 'required|exists:users,id', 'booking_id' => 'nullable|exists:bookings,id', 'type' => 'required|string', 'title' => 'required|string', 'message' => 'required|string', 'data' => 'nullable|array']);

        return ApiResponse::success(Notifikasi::create($data), 'Notifikasi dibuat.', 201);
    }

    public function destroyNotification(Request $r, Notifikasi $notifikasi)
    {
        if ($notifikasi->user_id !== $r->user()->id && ! $r->user()->isRole('ADMIN')) {
            return ApiResponse::error('Tidak diizinkan.', null, 403);
        }
        $notifikasi->delete();

        return ApiResponse::success(null, 'Notifikasi dihapus.');
    }

    private function ensureChatAllowed(Request $request, Booking $booking): void
    {
        $allowedStatuses = [Booking::DIKIRIM_KE_PELAYAN, Booking::DITERIMA_PELAYAN, Booking::MENUJU_LOKASI, Booking::SEDANG_DIKERJAKAN, Booking::SELESAI];
        abort_unless(in_array($booking->status, $allowedStatuses, true), 422, 'Chat aktif setelah pelayan ditugaskan.');
        $user = $request->user();
        abort_unless($user->isRole('ADMIN') || $booking->user_id === $user->id || $booking->mitra?->user_id === $user->id || $booking->pelayan?->user_id === $user->id, 403);
    }
}
