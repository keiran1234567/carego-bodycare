<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\Booking;
use App\Services\PaymentService;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function __construct(private PaymentService $service) {}

    public function create(Request $request, Booking $booking)
    {
        if ($booking->user_id !== $request->user()->id) {
            return ApiResponse::error('Tidak diizinkan.', null, 403);
        }

        return ApiResponse::success($this->service->create($booking->load('user')), 'Snap token dibuat.', 201);
    }

    public function callback(Request $request)
    {
        return ApiResponse::success($this->service->callback($request->all()), 'Callback diproses.');
    }

    public function status(Request $request, Booking $booking)
    {
        if ($booking->user_id !== $request->user()->id) {
            return ApiResponse::error('Tidak diizinkan.', null, 403);
        }

        return ApiResponse::success($this->service->sync($booking), 'Status pembayaran disinkronkan.');
    }
}
