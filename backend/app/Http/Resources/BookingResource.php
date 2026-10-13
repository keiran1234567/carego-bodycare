<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BookingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'booking_code' => $this->booking_code,
            'status' => $this->status,
            'scheduled_at' => $this->scheduled_at,
            'service_address' => $this->service_address,
            'service_latitude' => $this->service_latitude,
            'service_longitude' => $this->service_longitude,
            'travel_distance_km' => $this->travel_distance_km,
            'travel_fee' => $this->travel_fee,
            'notes' => $this->notes,
            'subtotal' => $this->subtotal,
            'discount_amount' => $this->discount_amount,
            'total_price' => $this->total_price,
            'user' => $this->whenLoaded('user'),
            'mitra' => $this->whenLoaded('mitra'),
            'pelayan' => $this->whenLoaded('pelayan'),
            'layanan' => $this->whenLoaded('layanan'),
            'voucher' => $this->whenLoaded('voucher'),
            'pembayaran' => $this->whenLoaded('pembayaran'),
            'review' => $this->whenLoaded('review'),
            'riwayats' => $this->whenLoaded('riwayats'),
        ];
    }
}
