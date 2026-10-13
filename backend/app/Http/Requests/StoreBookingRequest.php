<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreBookingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->isRole('USER');
    }

    public function rules(): array
    {
        return ['mitra_id' => 'required|exists:mitras,id', 'pelayan_id' => 'required|exists:pelayans,id', 'layanan_id' => 'required|exists:layanans,id', 'scheduled_at' => 'required|date|after:now', 'service_address' => 'required|string|max:1000', 'service_latitude' => 'nullable|numeric|between:-90,90', 'service_longitude' => 'nullable|numeric|between:-180,180', 'travel_distance_km' => 'nullable|numeric|min:0|max:8', 'notes' => 'nullable|string|max:1000', 'voucher_code' => 'nullable|string|max:50'];
    }
}
