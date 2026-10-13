<?php

namespace Database\Seeders;

use App\Models\Voucher;
use Illuminate\Database\Seeder;

class VoucherSeeder extends Seeder
{
    public function run(): void
    {
        Voucher::updateOrCreate(['code' => 'CAREGO20'], [
            'name' => 'Diskon CareGo 20%',
            'description' => 'Diskon 20% untuk semua layanan CareGo.',
            'discount_type' => 'PERCENT',
            'discount_value' => 20,
            'max_discount' => 50000,
            'min_transaction' => 100000,
            'starts_at' => now()->subDay(),
            'expires_at' => now()->addMonths(3),
            'quota' => 100,
            'is_active' => true,
        ]);
        Voucher::updateOrCreate(['code' => 'HEMAT25K'], [
            'name' => 'Potongan Rp25.000',
            'description' => 'Potongan langsung untuk transaksi minimal Rp100.000.',
            'discount_type' => 'FIXED',
            'discount_value' => 25000,
            'min_transaction' => 100000,
            'starts_at' => now()->subDay(),
            'expires_at' => now()->addMonths(3),
            'quota' => 100,
            'is_active' => true,
        ]);
    }
}
