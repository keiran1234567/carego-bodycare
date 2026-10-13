<?php

namespace App\Repositories\Contracts;

use App\Models\Booking;

interface BookingRepositoryInterface
{
    public function create(array $data): Booking;

    public function detailed(Booking $booking): Booking;

    public function forUser(int $userId);

    public function forMitra(int $mitraId);

    public function forPelayan(int $pelayanId);

    public function forAdmin();
}
