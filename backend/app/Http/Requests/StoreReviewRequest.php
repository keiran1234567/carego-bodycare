<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreReviewRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return ['booking_id' => 'required|exists:bookings,id|unique:reviews,booking_id', 'rating' => 'required|integer|min:1|max:5', 'review' => 'nullable|string|max:2000', 'photo_urls' => 'nullable|array', 'photo_urls.*' => 'string|max:7000000'];
    }
}
