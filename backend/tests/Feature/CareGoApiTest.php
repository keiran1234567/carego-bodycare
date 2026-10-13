<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\Layanan;
use App\Models\Mitra;
use App\Models\Pelayan;
use App\Models\User;
use App\Models\Voucher;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class CareGoApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_manage_all_core_entities(): void
    {
        $admin = User::create(['name' => 'Admin', 'email' => 'admin-crud@test.dev', 'password' => 'password', 'role' => 'ADMIN']);

        $customer = $this->actingAs($admin)->postJson('/api/v1/admin/users', [
            'name' => 'Customer CRUD',
            'email' => 'customer-crud@test.dev',
            'phone' => '0811111111',
            'password' => 'password',
            'role' => 'USER',
            'status' => 'ACTIVE',
        ])->assertCreated()->json('data');
        $this->actingAs($admin)->patchJson("/api/v1/admin/users/{$customer['id']}", [
            'name' => 'Customer Updated',
        ])->assertOk()->assertJsonPath('data.name', 'Customer Updated');

        $mitra = $this->actingAs($admin)->postJson('/api/v1/mitras', [
            'name' => 'Mitra CRUD',
            'email' => 'mitra-crud@test.dev',
            'phone' => '0822222222',
            'password' => 'password',
            'address' => 'Alamat Mitra',
            'description' => 'Mitra pengujian',
            'is_verified' => true,
        ])->assertCreated()->json('data');
        $this->actingAs($admin)->patchJson("/api/v1/mitras/{$mitra['id']}", [
            'name' => 'Mitra CRUD Updated',
        ])->assertOk()->assertJsonPath('data.name', 'Mitra CRUD Updated');

        $pelayan = $this->actingAs($admin)->postJson('/api/v1/pelayans', [
            'mitra_id' => $mitra['id'],
            'name' => 'Pelayan CRUD',
            'email' => 'pelayan-crud@test.dev',
            'phone' => '0833333333',
            'password' => 'password',
            'specialization' => 'Cukur Rambut',
            'experience_years' => 2,
        ])->assertCreated()->json('data');
        $this->actingAs($admin)->patchJson("/api/v1/pelayans/{$pelayan['id']}", [
            'name' => 'Pelayan Updated',
            'specialization' => 'Cukur Rambut, Salon',
        ])->assertOk()->assertJsonPath('data.user.name', 'Pelayan Updated');

        $service = $this->actingAs($admin)->postJson('/api/v1/layanans', [
            'mitra_id' => $mitra['id'],
            'name' => 'Cukur CRUD',
            'category' => 'Cukur Rambut',
            'description' => 'Layanan tes',
            'price' => 100000,
            'duration_minutes' => 60,
        ])->assertCreated()->json('data');
        $this->actingAs($admin)->patchJson("/api/v1/layanans/{$service['id']}", [
            'price' => 120000,
        ])->assertOk()->assertJsonPath('data.price', '120000.00');

        $booking = $this->actingAs($admin)->postJson('/api/v1/admin/bookings', [
            'user_id' => $customer['id'],
            'mitra_id' => $mitra['id'],
            'pelayan_id' => $pelayan['id'],
            'layanan_id' => $service['id'],
            'scheduled_at' => now()->addDay()->toIso8601String(),
            'service_address' => 'Alamat Customer',
            'travel_distance_km' => 2,
        ])->assertCreated()->json('data');
        $this->actingAs($admin)->getJson('/api/v1/bookings')
            ->assertOk()->assertJsonCount(1, 'data.data');

        $payment = $this->actingAs($admin)->postJson('/api/v1/admin/payments', [
            'id_booking' => $booking['id'],
            'metode_pembayaran' => 'MANUAL',
            'status_pembayaran' => 'PAID',
            'total_bayar' => 130000,
        ])->assertCreated()
            ->assertJsonPath('data.komisi_platform', '13000.00')
            ->assertJsonPath('data.pendapatan_mitra', '39000.00')
            ->assertJsonPath('data.pendapatan_pelayan', '78000.00')
            ->json('data');
        $this->actingAs($admin)->patchJson("/api/v1/admin/payments/{$payment['id_pembayaran']}", [
            'id_booking' => $booking['id'],
            'metode_pembayaran' => 'TRANSFER',
            'status_pembayaran' => 'PENDING',
            'total_bayar' => 130000,
        ])->assertOk()->assertJsonPath('data.metode_pembayaran', 'TRANSFER');

        $this->actingAs($admin)->deleteJson("/api/v1/admin/payments/{$payment['id_pembayaran']}")->assertOk();
        $this->actingAs($admin)->deleteJson("/api/v1/admin/bookings/{$booking['id']}")->assertOk();
        $this->actingAs($admin)->deleteJson("/api/v1/layanans/{$service['id']}")->assertOk();
        $this->actingAs($admin)->deleteJson("/api/v1/pelayans/{$pelayan['id']}")->assertOk();
        $this->actingAs($admin)->deleteJson("/api/v1/mitras/{$mitra['id']}")->assertOk();
        $this->actingAs($admin)->deleteJson("/api/v1/admin/users/{$customer['id']}")->assertOk();

        $this->assertDatabaseMissing('pembayarans', ['id_pembayaran' => $payment['id_pembayaran']]);
        $this->assertDatabaseMissing('bookings', ['id' => $booking['id']]);
        $this->assertDatabaseMissing('users', ['email' => 'customer-crud@test.dev']);
        $this->assertDatabaseMissing('users', ['email' => 'mitra-crud@test.dev']);
        $this->assertDatabaseMissing('users', ['email' => 'pelayan-crud@test.dev']);
    }

    public function test_user_can_login_and_open_dashboard(): void
    {
        $user = User::create(['name' => 'User', 'email' => 'user@test.dev', 'password' => 'password', 'role' => 'USER']);
        $this->postJson('/api/v1/auth/login', ['email' => $user->email, 'password' => 'password', 'role' => 'USER'])->assertOk()->assertJsonPath('success', true)->assertJsonStructure(['data' => ['token']]);
        $this->actingAs($user)->getJson('/api/v1/dashboard')->assertOk()->assertJsonPath('data.bookings', 0);
    }

    public function test_login_rejects_wrong_role(): void
    {
        $user = User::create(['name' => 'User', 'email' => 'user@test.dev', 'password' => 'password', 'role' => 'USER']);

        $this->postJson('/api/v1/auth/login', ['email' => $user->email, 'password' => 'password', 'role' => 'MITRA'])->assertUnauthorized()->assertJsonPath('success', false);
    }

    public function test_admin_can_register(): void
    {
        $this->postJson('/api/v1/auth/register', ['name' => 'Admin Baru', 'email' => 'adminbaru@test.dev', 'phone' => '08123456789', 'password' => 'password', 'password_confirmation' => 'password', 'role' => 'ADMIN'])->assertCreated()->assertJsonPath('success', true)->assertJsonPath('data.user.role', 'ADMIN')->assertJsonStructure(['data' => ['token']]);

        $this->assertDatabaseHas('users', ['email' => 'adminbaru@test.dev', 'role' => 'ADMIN']);
    }

    public function test_partner_registration_waits_for_admin_verification_and_sends_email(): void
    {
        Mail::fake();

        $image = base64_encode(str_repeat('a', 32));
        $registered = $this->postJson('/api/v1/auth/register', [
            'name' => 'Pemilik Mitra',
            'email' => 'pending-mitra@test.dev',
            'phone' => '08123456789',
            'password' => 'password',
            'password_confirmation' => 'password',
            'role' => 'MITRA',
            'business_name' => 'Mitra Pending CareGo',
            'address' => 'Jl. Pending No. 1',
            'description' => 'Usaha layanan kecantikan rumahan.',
            'ktp_image_base64' => $image,
            'logo_image_base64' => $image,
        ])->assertCreated()
            ->assertJsonPath('data.user.status', 'PENDING')
            ->assertJsonPath('data.user.mitra.verification_status', 'pending')
            ->json('data.user');

        $admin = User::create([
            'name' => 'Admin',
            'email' => 'admin-verify@test.dev',
            'password' => 'password',
            'role' => 'ADMIN',
        ]);
        $mitra = Mitra::where('user_id', $registered['id'])->firstOrFail();

        $this->actingAs($admin)->postJson("/api/v1/mitras/{$mitra->id}/approve")
            ->assertOk()
            ->assertJsonPath('data.verification_status', 'approved')
            ->assertJsonPath('data.is_verified', true);

        Mail::assertSentCount(1);

        $this->actingAs($admin)->postJson("/api/v1/mitras/{$mitra->id}/reject", [
            'reason' => 'Foto KTP kurang jelas.',
        ])->assertOk()
            ->assertJsonPath('data.verification_status', 'rejected')
            ->assertJsonPath('data.rejection_reason', 'Foto KTP kurang jelas.');

        Mail::assertSentCount(2);
    }

    public function test_complete_booking_payment_and_status_flow(): void
    {
        $user = User::create(['name' => 'User', 'email' => 'u@test.dev', 'password' => 'password', 'role' => 'USER']);
        $mu = User::create(['name' => 'Mitra', 'email' => 'm@test.dev', 'password' => 'password', 'role' => 'MITRA']);
        $mitra = Mitra::create(['user_id' => $mu->id, 'name' => 'Mitra', 'address' => 'Alamat']);
        $pu = User::create(['name' => 'Pelayan', 'email' => 'p@test.dev', 'password' => 'password', 'role' => 'PELAYAN']);
        $pelayan = Pelayan::create(['user_id' => $pu->id, 'mitra_id' => $mitra->id, 'specialization' => 'Facial']);
        $layanan = Layanan::create(['mitra_id' => $mitra->id, 'name' => 'Facial', 'category' => 'Facial', 'price' => 100000, 'duration_minutes' => 60]);
        $response = $this->actingAs($user)->postJson('/api/v1/bookings', ['mitra_id' => $mitra->id, 'pelayan_id' => $pelayan->id, 'layanan_id' => $layanan->id, 'scheduled_at' => now()->addDay()->toIso8601String(), 'service_address' => 'Rumah']);
        $response->assertCreated();
        $booking = Booking::first();
        $payment = $this->actingAs($user)->postJson("/api/v1/bookings/{$booking->id}/payment")->assertCreated()->json('data');
        $this->postJson('/api/v1/payments/midtrans/callback', ['order_id' => $payment['midtrans_order_id'], 'status_code' => '200', 'gross_amount' => '100000.00', 'transaction_status' => 'settlement', 'payment_type' => 'qris'])->assertOk();
        $this->assertDatabaseHas('bookings', ['id' => $booking->id, 'status' => Booking::MENUNGGU_KONFIRMASI_MITRA]);
        foreach ([[$mu, Booking::DITERIMA_MITRA], [$mu, Booking::DIKIRIM_KE_PELAYAN], [$pu, Booking::DITERIMA_PELAYAN], [$pu, Booking::MENUJU_LOKASI], [$pu, Booking::SEDANG_DIKERJAKAN], [$pu, Booking::SELESAI]] as [$actor,$status]) {
            $this->actingAs($actor)->patchJson("/api/v1/bookings/{$booking->id}/status", ['status' => $status])->assertOk();
        }
        $this->actingAs($user)->postJson('/api/v1/reviews', ['booking_id' => $booking->id, 'rating' => 5, 'review' => 'Mantap'])->assertCreated();
    }

    public function test_newly_registered_user_booking_has_payable_total(): void
    {
        $mitraUser = User::create(['name' => 'Mitra', 'email' => 'mitra-new@test.dev', 'password' => 'password', 'role' => 'MITRA']);
        $mitra = Mitra::create(['user_id' => $mitraUser->id, 'name' => 'Mitra', 'address' => 'Alamat']);
        $pelayanUser = User::create(['name' => 'Pelayan', 'email' => 'pelayan-new@test.dev', 'password' => 'password', 'role' => 'PELAYAN']);
        $pelayan = Pelayan::create(['user_id' => $pelayanUser->id, 'mitra_id' => $mitra->id, 'specialization' => 'Facial']);
        $layanan = Layanan::create(['mitra_id' => $mitra->id, 'name' => 'Facial', 'category' => 'Facial', 'price' => 125000, 'duration_minutes' => 60]);

        $registered = $this->postJson('/api/v1/auth/register', [
            'name' => 'User Baru',
            'email' => 'user-baru@test.dev',
            'phone' => '08123456789',
            'password' => 'password',
            'password_confirmation' => 'password',
            'role' => 'USER',
        ])->assertCreated();
        $user = User::findOrFail($registered->json('data.user.id'));

        $booking = $this->actingAs($user)->postJson('/api/v1/bookings', [
            'mitra_id' => $mitra->id,
            'pelayan_id' => $pelayan->id,
            'layanan_id' => $layanan->id,
            'scheduled_at' => now()->addDay()->toIso8601String(),
            'service_address' => 'Rumah user baru',
        ])->assertCreated()
            ->assertJsonPath('data.travel_fee', '10000.00')
            ->assertJsonPath('data.total_price', '135000.00')
            ->json('data');

        $this->actingAs($user)->postJson("/api/v1/bookings/{$booking['id']}/payment")
            ->assertCreated()
            ->assertJsonPath('data.total_bayar', '135000.00');
    }

    public function test_user_cannot_create_payment_for_another_users_booking(): void
    {
        $owner = User::create(['name' => 'Owner', 'email' => 'owner@test.dev', 'password' => 'password', 'role' => 'USER']);
        $other = User::create(['name' => 'Other', 'email' => 'other@test.dev', 'password' => 'password', 'role' => 'USER']);
        $mitraUser = User::create(['name' => 'Mitra', 'email' => 'mitra-owner@test.dev', 'password' => 'password', 'role' => 'MITRA']);
        $mitra = Mitra::create(['user_id' => $mitraUser->id, 'name' => 'Mitra', 'address' => 'Alamat']);
        $pelayanUser = User::create(['name' => 'Pelayan', 'email' => 'pelayan-owner@test.dev', 'password' => 'password', 'role' => 'PELAYAN']);
        $pelayan = Pelayan::create(['user_id' => $pelayanUser->id, 'mitra_id' => $mitra->id, 'specialization' => 'Facial']);
        $layanan = Layanan::create(['mitra_id' => $mitra->id, 'name' => 'Facial', 'category' => 'Facial', 'price' => 100000, 'duration_minutes' => 60]);
        $booking = Booking::create(['booking_code' => 'CG-OWNER-001', 'user_id' => $owner->id, 'mitra_id' => $mitra->id, 'pelayan_id' => $pelayan->id, 'layanan_id' => $layanan->id, 'scheduled_at' => now()->addDay(), 'service_address' => 'Rumah', 'total_price' => 100000, 'status' => Booking::MENUNGGU_PEMBAYARAN]);

        $this->actingAs($other)->postJson("/api/v1/bookings/{$booking->id}/payment")->assertForbidden();
    }

    public function test_voucher_reduces_booking_total_and_records_usage(): void
    {
        $user = User::create(['name' => 'User Voucher', 'email' => 'voucher-user@test.dev', 'password' => 'password', 'role' => 'USER']);
        $mitraUser = User::create(['name' => 'Mitra Voucher', 'email' => 'voucher-mitra@test.dev', 'password' => 'password', 'role' => 'MITRA']);
        $mitra = Mitra::create(['user_id' => $mitraUser->id, 'name' => 'Mitra Voucher', 'address' => 'Alamat']);
        $pelayanUser = User::create(['name' => 'Pelayan Voucher', 'email' => 'voucher-pelayan@test.dev', 'password' => 'password', 'role' => 'PELAYAN']);
        $pelayan = Pelayan::create(['user_id' => $pelayanUser->id, 'mitra_id' => $mitra->id, 'specialization' => 'Facial']);
        $layanan = Layanan::create(['mitra_id' => $mitra->id, 'name' => 'Facial Voucher', 'category' => 'Facial', 'price' => 200000, 'duration_minutes' => 60]);
        $voucher = Voucher::create(['code' => 'TEST20', 'name' => 'Test 20%', 'discount_type' => 'PERCENT', 'discount_value' => 20, 'max_discount' => 30000, 'min_transaction' => 100000, 'quota' => 1, 'used_count' => 0, 'is_active' => true, 'expires_at' => now()->addDay()]);

        $this->actingAs($user)->postJson('/api/v1/bookings', [
            'mitra_id' => $mitra->id,
            'pelayan_id' => $pelayan->id,
            'layanan_id' => $layanan->id,
            'scheduled_at' => now()->addDay()->toIso8601String(),
            'service_address' => 'Rumah',
            'voucher_code' => 'test20',
        ])->assertCreated()
            ->assertJsonPath('data.subtotal', '200000.00')
            ->assertJsonPath('data.discount_amount', '30000.00')
            ->assertJsonPath('data.travel_fee', '10000.00')
            ->assertJsonPath('data.total_price', '180000.00');

        $this->assertDatabaseHas('voucher_usages', ['voucher_id' => $voucher->id, 'user_id' => $user->id, 'discount_amount' => 30000]);
        $this->assertDatabaseHas('vouchers', ['id' => $voucher->id, 'used_count' => 1]);
        $this->actingAs($user)->getJson('/api/v1/voucher-history')->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_user_can_save_address_with_current_coordinates(): void
    {
        $user = User::create(['name' => 'User Lokasi', 'email' => 'location-user@test.dev', 'password' => 'password', 'role' => 'USER']);

        $this->actingAs($user)->postJson('/api/v1/addresses', [
            'label' => 'Lokasi Saya',
            'address' => 'Jl. Contoh Lokasi, Jakarta',
            'latitude' => -6.2000000,
            'longitude' => 106.8166667,
            'is_primary' => true,
        ])->assertCreated()
            ->assertJsonPath('data.is_primary', true)
            ->assertJsonPath('data.latitude', -6.2)
            ->assertJsonPath('data.longitude', 106.8166667);

        $this->assertDatabaseHas('addresses', [
            'user_id' => $user->id,
            'label' => 'Lokasi Saya',
            'latitude' => -6.2000000,
            'longitude' => 106.8166667,
        ]);
    }

    public function test_mitra_can_create_employee_account_and_manage_own_catalog(): void
    {
        $mitraUser = User::create(['name' => 'Mitra', 'email' => 'mitra-manage@test.dev', 'password' => 'password', 'role' => 'MITRA']);
        $mitra = Mitra::create(['user_id' => $mitraUser->id, 'name' => 'Mitra Manage', 'address' => 'Alamat']);

        $employee = $this->actingAs($mitraUser)->postJson('/api/v1/pelayans', [
            'name' => 'Pelayan Baru',
            'email' => 'pelayan-created@test.dev',
            'phone' => '08123456789',
            'password' => 'password',
            'specialization' => 'Facial',
            'experience_years' => 2,
        ])->assertCreated()->assertJsonPath('data.mitra_id', $mitra->id)->json('data');

        $this->assertDatabaseHas('users', ['email' => 'pelayan-created@test.dev', 'role' => 'PELAYAN']);
        $this->actingAs($mitraUser)->patchJson("/api/v1/pelayans/{$employee['id']}", ['is_available' => false])
            ->assertOk()->assertJsonPath('data.is_available', false);

        $service = $this->actingAs($mitraUser)->postJson('/api/v1/layanans', [
            'name' => 'Facial Baru',
            'category' => 'Facial',
            'description' => 'Layanan backend',
            'price' => 150000,
            'duration_minutes' => 75,
        ])->assertCreated()->assertJsonPath('data.mitra_id', $mitra->id)->json('data');

        $this->actingAs($mitraUser)->patchJson("/api/v1/layanans/{$service['id']}", ['price' => 175000])
            ->assertOk()->assertJsonPath('data.price', '175000.00');
    }

    public function test_mitra_cannot_change_another_mitras_employee_or_service(): void
    {
        $firstUser = User::create(['name' => 'Mitra 1', 'email' => 'mitra-one@test.dev', 'password' => 'password', 'role' => 'MITRA']);
        Mitra::create(['user_id' => $firstUser->id, 'name' => 'Mitra 1', 'address' => 'Alamat']);
        $secondUser = User::create(['name' => 'Mitra 2', 'email' => 'mitra-two@test.dev', 'password' => 'password', 'role' => 'MITRA']);
        $second = Mitra::create(['user_id' => $secondUser->id, 'name' => 'Mitra 2', 'address' => 'Alamat']);
        $employeeUser = User::create(['name' => 'Pelayan 2', 'email' => 'pelayan-two@test.dev', 'password' => 'password', 'role' => 'PELAYAN']);
        $employee = Pelayan::create(['user_id' => $employeeUser->id, 'mitra_id' => $second->id, 'specialization' => 'Spa']);
        $service = Layanan::create(['mitra_id' => $second->id, 'name' => 'Spa', 'category' => 'Spa', 'price' => 100000, 'duration_minutes' => 60]);

        $this->actingAs($firstUser)->patchJson("/api/v1/pelayans/{$employee->id}", ['is_available' => false])->assertForbidden();
        $this->actingAs($firstUser)->patchJson("/api/v1/layanans/{$service->id}", ['price' => 1])->assertForbidden();
    }

    public function test_pelayan_can_only_update_own_availability(): void
    {
        $mitraUser = User::create(['name' => 'Mitra', 'email' => 'mitra-availability@test.dev', 'password' => 'password', 'role' => 'MITRA']);
        $mitra = Mitra::create(['user_id' => $mitraUser->id, 'name' => 'Mitra', 'address' => 'Alamat']);
        $firstUser = User::create(['name' => 'Pelayan 1', 'email' => 'pelayan-availability-one@test.dev', 'password' => 'password', 'role' => 'PELAYAN']);
        $first = Pelayan::create(['user_id' => $firstUser->id, 'mitra_id' => $mitra->id, 'specialization' => 'Facial']);
        $secondUser = User::create(['name' => 'Pelayan 2', 'email' => 'pelayan-availability-two@test.dev', 'password' => 'password', 'role' => 'PELAYAN']);
        $second = Pelayan::create(['user_id' => $secondUser->id, 'mitra_id' => $mitra->id, 'specialization' => 'Spa']);

        $this->actingAs($firstUser)->patchJson("/api/v1/pelayans/{$first->id}", ['is_available' => false])
            ->assertOk()->assertJsonPath('data.is_available', false);
        $this->actingAs($firstUser)->patchJson("/api/v1/pelayans/{$second->id}", ['is_available' => false])
            ->assertForbidden();
    }

    public function test_pelayan_only_receives_booking_after_mitra_sends_it(): void
    {
        $user = User::create(['name' => 'User', 'email' => 'flow-user@test.dev', 'password' => 'password', 'role' => 'USER']);
        $mitraUser = User::create(['name' => 'Mitra', 'email' => 'flow-mitra@test.dev', 'password' => 'password', 'role' => 'MITRA']);
        $mitra = Mitra::create(['user_id' => $mitraUser->id, 'name' => 'Mitra Flow', 'address' => 'Alamat']);
        $pelayanUser = User::create(['name' => 'Pelayan', 'email' => 'flow-pelayan@test.dev', 'password' => 'password', 'role' => 'PELAYAN']);
        $pelayan = Pelayan::create(['user_id' => $pelayanUser->id, 'mitra_id' => $mitra->id, 'specialization' => 'Facial']);
        $layanan = Layanan::create(['mitra_id' => $mitra->id, 'name' => 'Facial Flow', 'category' => 'Facial', 'price' => 100000, 'duration_minutes' => 60]);
        $booking = Booking::create([
            'booking_code' => 'CG-FLOW-001',
            'user_id' => $user->id,
            'mitra_id' => $mitra->id,
            'pelayan_id' => $pelayan->id,
            'layanan_id' => $layanan->id,
            'scheduled_at' => now()->addDay()->setTime(9, 0),
            'service_address' => 'Rumah',
            'total_price' => 110000,
            'status' => Booking::DITERIMA_MITRA,
        ]);

        $this->actingAs($pelayanUser)->getJson('/api/v1/bookings')
            ->assertOk()->assertJsonCount(0, 'data.data');

        $this->actingAs($mitraUser)->patchJson("/api/v1/bookings/{$booking->id}/status", [
            'status' => Booking::DIKIRIM_KE_PELAYAN,
        ])->assertOk();

        $this->actingAs($pelayanUser)->getJson('/api/v1/bookings')
            ->assertOk()
            ->assertJsonCount(1, 'data.data')
            ->assertJsonPath('data.data.0.status', Booking::DIKIRIM_KE_PELAYAN)
            ->assertJsonPath('data.data.0.scheduled_at', $booking->scheduled_at->toJSON());
    }
}
