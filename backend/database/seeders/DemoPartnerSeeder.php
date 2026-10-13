<?php

namespace Database\Seeders;

use App\Models\Layanan;
use App\Models\Mitra;
use App\Models\Pelayan;
use App\Models\Portofolio;
use App\Models\User;
use Illuminate\Database\Seeder;

class DemoPartnerSeeder extends Seeder
{
    public function run(): void
    {
        $this->createPartnerPackage(
            mitraName: 'Barber House CareGo',
            mitraEmail: 'barber.mitra@carego.test',
            mitraPhone: '081100000101',
            mitraAddress: 'Jl. Melati Raya No. 21, Jakarta Selatan',
            mitraDescription: 'Mitra khusus layanan grooming dan cukur rambut pria di rumah.',
            pelayanName: 'Rizky Pratama',
            pelayanEmail: 'rizky.pelayan@carego.test',
            pelayanPhone: '081100000102',
            specialization: 'Cukur Rambut',
            serviceName: 'Cukur Rambut Premium',
            category: 'Barber',
            price: 65000,
            durationMinutes: 45,
            imageUrl: 'https://images.unsplash.com/photo-1599351431202-1e0f0137899a',
            portfolioTitle: 'Hasil Cukur Rapi',
            portfolioImageUrl: 'https://images.unsplash.com/photo-1622288432450-277d0fef5ed6',
        );

        $this->createPartnerPackage(
            mitraName: 'Nail Art Studio CareGo',
            mitraEmail: 'nail.mitra@carego.test',
            mitraPhone: '081100000103',
            mitraAddress: 'Jl. Anggrek Indah No. 8, Jakarta Barat',
            mitraDescription: 'Mitra layanan nail care dan nail art profesional panggilan ke rumah.',
            pelayanName: 'Dewi Anggraini',
            pelayanEmail: 'dewi.pelayan@carego.test',
            pelayanPhone: '081100000104',
            specialization: 'Nail Art',
            serviceName: 'Nail Art Premium',
            category: 'Nail Care',
            price: 185000,
            durationMinutes: 75,
            imageUrl: 'https://images.unsplash.com/photo-1604654894610-df63bc536371',
            portfolioTitle: 'Nail Art Floral',
            portfolioImageUrl: 'https://images.unsplash.com/photo-1610992015732-2449b76344bc',
        );
    }

    private function createPartnerPackage(
        string $mitraName,
        string $mitraEmail,
        string $mitraPhone,
        string $mitraAddress,
        string $mitraDescription,
        string $pelayanName,
        string $pelayanEmail,
        string $pelayanPhone,
        string $specialization,
        string $serviceName,
        string $category,
        int $price,
        int $durationMinutes,
        string $imageUrl,
        string $portfolioTitle,
        string $portfolioImageUrl,
    ): void {
        $mitraUser = User::updateOrCreate(
            ['email' => $mitraEmail],
            [
                'name' => $mitraName,
                'phone' => $mitraPhone,
                'password' => 'password',
                'role' => 'MITRA',
                'status' => 'ACTIVE',
                'address' => $mitraAddress,
            ],
        );

        $mitra = Mitra::updateOrCreate(
            ['user_id' => $mitraUser->id],
            [
                'name' => $mitraName,
                'address' => $mitraAddress,
                'description' => $mitraDescription,
                'open_hours' => '08:00 - 21:00',
                'rating' => 4.8,
                'is_verified' => true,
                'cover_url' => $imageUrl,
            ],
        );

        $pelayanUser = User::updateOrCreate(
            ['email' => $pelayanEmail],
            [
                'name' => $pelayanName,
                'phone' => $pelayanPhone,
                'password' => 'password',
                'role' => 'PELAYAN',
                'status' => 'ACTIVE',
            ],
        );

        $pelayan = Pelayan::updateOrCreate(
            ['user_id' => $pelayanUser->id],
            [
                'mitra_id' => $mitra->id,
                'specialization' => $specialization,
                'bio' => "Spesialis layanan {$specialization} untuk pelanggan CareGo.",
                'experience_years' => 3,
                'rating' => 4.9,
                'is_available' => true,
            ],
        );

        Layanan::updateOrCreate(
            [
                'mitra_id' => $mitra->id,
                'name' => $serviceName,
            ],
            [
                'category' => $category,
                'description' => "Layanan {$serviceName} dikerjakan oleh {$pelayan->user->name}.",
                'price' => $price,
                'duration_minutes' => $durationMinutes,
                'image_url' => $imageUrl,
                'is_active' => true,
            ],
        );

        Portofolio::updateOrCreate(
            [
                'pelayan_id' => $pelayan->id,
                'title' => $portfolioTitle,
            ],
            [
                'description' => "Contoh hasil kerja {$specialization}.",
                'image_url' => $portfolioImageUrl,
            ],
        );
    }
}
