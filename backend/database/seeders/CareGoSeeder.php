<?php

namespace Database\Seeders;

use App\Models\Booking;
use App\Models\Layanan;
use App\Models\Mitra;
use App\Models\Notifikasi;
use App\Models\Pelayan;
use App\Models\Portofolio;
use App\Models\Riwayat;
use App\Models\User;
use App\Models\Address;
use App\Models\Voucher;
use Illuminate\Database\Seeder;

class CareGoSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::create(['name' => 'Admin CareGo', 'email' => 'admin@carego.test', 'phone' => '081100000001', 'password' => 'password', 'role' => 'ADMIN']);
        $user = User::create(['name' => 'Keiran', 'email' => 'user@carego.test', 'phone' => '081100000002', 'password' => 'password', 'role' => 'USER', 'address' => 'Jl. Kencana Indah No. 12, Jakarta Selatan']);
        $mu = User::create(['name' => 'Glow Beauty', 'email' => 'mitra@carego.test', 'phone' => '081100000003', 'password' => 'password', 'role' => 'MITRA']);
        $mitra = Mitra::create(['user_id' => $mu->id, 'name' => 'Glow Beauty Home Service', 'address' => 'Jl. Kemang Raya No. 15, Jakarta Selatan', 'description' => 'Perawatan kecantikan profesional di rumah Anda.', 'open_hours' => '08:00 - 22:00', 'rating' => 4.8, 'is_verified' => true, 'cover_url' => 'https://images.unsplash.com/photo-1560066984-138dadb4c035']);
        $pu = User::create(['name' => 'Sinta Aprilia', 'email' => 'pelayan@carego.test', 'phone' => '081100000004', 'password' => 'password', 'role' => 'PELAYAN']);
        $pelayan = Pelayan::create(['user_id' => $pu->id, 'mitra_id' => $mitra->id, 'specialization' => 'Terapis Kecantikan', 'bio' => 'Spesialis facial dan perawatan kulit.', 'experience_years' => 3, 'rating' => 4.9]);
        $layanan = Layanan::create(['mitra_id' => $mitra->id, 'name' => 'Facial Basic', 'category' => 'Facial', 'description' => 'Perawatan wajah dasar untuk membersihkan dan menyegarkan kulit.', 'price' => 120000, 'duration_minutes' => 60, 'image_url' => 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881']);
        Portofolio::create(['pelayan_id' => $pelayan->id, 'title' => 'Facial Glow', 'description' => 'Hasil facial pelanggan', 'image_url' => 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881']);
        $booking = Booking::create(['booking_code' => 'CG-DEMO-001', 'user_id' => $user->id, 'mitra_id' => $mitra->id, 'pelayan_id' => $pelayan->id, 'layanan_id' => $layanan->id, 'scheduled_at' => now()->addDays(2), 'service_address' => $user->address, 'notes' => 'Fokus area komedo.', 'total_price' => $layanan->price, 'status' => Booking::MENUNGGU_PEMBAYARAN]);
        Riwayat::create(['booking_id' => $booking->id, 'status' => $booking->status, 'description' => 'Booking demo dibuat.', 'changed_by' => $user->id]);
        Notifikasi::create(['user_id' => $user->id, 'booking_id' => $booking->id, 'type' => 'BOOKING', 'title' => 'Booking Dibuat', 'message' => 'Booking Facial Basic berhasil dibuat.']);
        Address::create(['user_id' => $user->id, 'label' => 'Rumah', 'address' => $user->address, 'is_primary' => true]);
        Voucher::create(['code' => 'CAREGO20', 'name' => 'Diskon CareGo 20%', 'description' => 'Diskon 20% untuk semua layanan CareGo.', 'discount_type' => 'PERCENT', 'discount_value' => 20, 'max_discount' => 50000, 'min_transaction' => 100000, 'starts_at' => now()->subDay(), 'expires_at' => now()->addMonths(3), 'quota' => 100, 'used_count' => 0, 'is_active' => true]);
        Voucher::create(['code' => 'HEMAT25K', 'name' => 'Potongan Rp25.000', 'description' => 'Potongan langsung untuk transaksi minimal Rp100.000.', 'discount_type' => 'FIXED', 'discount_value' => 25000, 'min_transaction' => 100000, 'starts_at' => now()->subDay(), 'expires_at' => now()->addMonths(3), 'quota' => 100, 'used_count' => 0, 'is_active' => true]);
    }
}
