<?php

namespace Database\Seeders;

use App\Models\Booking;
use App\Models\Chat;
use App\Models\Layanan;
use App\Models\Mitra;
use App\Models\Notifikasi;
use App\Models\Pelayan;
use App\Models\Pembayaran;
use App\Models\Review;
use App\Models\Riwayat;
use App\Models\User;
use Illuminate\Database\Seeder;

class PresentationSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::where('email', 'user@carego.test')->firstOrFail();
        $mitra = Mitra::where('name', 'Glow Beauty Home Service')->firstOrFail();
        $pelayan = Pelayan::where('mitra_id', $mitra->id)->firstOrFail();

        Layanan::where(function ($query) {
            $query->where('name', 'like', '%Spa%')
                ->orWhere('name', 'like', '%Massage%')
                ->orWhere('category', 'like', '%Spa%')
                ->orWhere('category', 'like', '%Massage%');
        })->update(['is_active' => false]);

        $services = collect([
            ['name' => 'Facial Basic', 'category' => 'Facial', 'description' => 'Perawatan wajah dasar untuk membersihkan dan menyegarkan kulit.', 'price' => 120000, 'duration_minutes' => 60, 'image_url' => 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881'],
            ['name' => 'Hair Treatment', 'category' => 'Salon', 'description' => 'Perawatan rambut profesional di rumah.', 'price' => 150000, 'duration_minutes' => 90, 'image_url' => 'https://images.unsplash.com/photo-1560066984-138dadb4c035'],
            ['name' => 'Nail Art Premium', 'category' => 'Nail Care', 'description' => 'Perawatan dan nail art dengan pilihan desain.', 'price' => 175000, 'duration_minutes' => 75, 'image_url' => 'https://images.unsplash.com/photo-1604654894610-df63bc536371'],
            ['name' => 'Make Up Natural', 'category' => 'Make Up', 'description' => 'Make-up natural untuk acara harian dan momen spesial.', 'price' => 165000, 'duration_minutes' => 75, 'image_url' => 'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2'],
        ])->map(fn (array $service) => Layanan::updateOrCreate(
            ['mitra_id' => $mitra->id, 'name' => $service['name']],
            [...$service, 'is_active' => true],
        ));

        $statuses = [
            Booking::MENUNGGU_PEMBAYARAN,
            Booking::MENUNGGU_KONFIRMASI_MITRA,
            Booking::DITERIMA_MITRA,
            Booking::DIKIRIM_KE_PELAYAN,
            Booking::DITERIMA_PELAYAN,
            Booking::MENUJU_LOKASI,
            Booking::SEDANG_DIKERJAKAN,
            Booking::SELESAI,
        ];

        foreach ($statuses as $index => $status) {
            $service = $services[$index % $services->count()];
            $booking = Booking::updateOrCreate(
                ['booking_code' => 'CG-PRESENTASI-'.str_pad((string) ($index + 1), 2, '0', STR_PAD_LEFT)],
                [
                    'user_id' => $user->id,
                    'mitra_id' => $mitra->id,
                    'pelayan_id' => $pelayan->id,
                    'layanan_id' => $service->id,
                    'scheduled_at' => now()->addDays($index + 1)->setTime(10 + ($index % 6), 0),
                    'service_address' => $user->address,
                    'notes' => 'Data presentasi dari backend.',
                    'total_price' => $service->price,
                    'status' => $status,
                ],
            );

            Riwayat::updateOrCreate(
                ['booking_id' => $booking->id, 'status' => $status],
                ['description' => 'Status booking presentasi: '.str_replace('_', ' ', $status), 'changed_by' => $user->id],
            );

            Notifikasi::updateOrCreate(
                ['user_id' => $user->id, 'booking_id' => $booking->id, 'title' => 'Booking '.$service->name],
                ['type' => 'BOOKING', 'message' => 'Status booking saat ini: '.str_replace('_', ' ', $status), 'data' => ['status' => $status]],
            );

            Chat::updateOrCreate(
                ['booking_id' => $booking->id, 'sender_id' => $mitra->user_id, 'receiver_id' => $user->id],
                ['message' => 'Halo, booking '.$service->name.' sudah kami terima dari backend.'],
            );

            if ($status !== Booking::MENUNGGU_PEMBAYARAN) {
                $total = (float) $service->price;
                Pembayaran::updateOrCreate(
                    ['id_booking' => $booking->id],
                    [
                        'midtrans_order_id' => 'CAREGO-DEMO-'.$booking->id,
                        'snap_token' => 'presentation-'.$booking->id,
                        'metode_pembayaran' => 'qris',
                        'total_bayar' => $total,
                        'status_pembayaran' => 'PAID',
                        'komisi_platform' => $total * .10,
                        'pendapatan_mitra' => $total * .20,
                        'pendapatan_pelayan' => $total * .70,
                        'waktu_bayar' => now(),
                    ],
                );
            }

            if ($status === Booking::SELESAI) {
                Review::updateOrCreate(
                    ['booking_id' => $booking->id],
                    ['user_id' => $user->id, 'mitra_id' => $mitra->id, 'pelayan_id' => $pelayan->id, 'rating' => 5, 'review' => 'Pelayanan sangat baik dan tepat waktu.'],
                );
            }
        }
    }
}
