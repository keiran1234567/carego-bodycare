<?php

namespace Tests\Feature;

use App\Models\Layanan;
use App\Models\Mitra;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminWebTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_login_and_open_web_dashboard(): void
    {
        $admin = User::create(['name' => 'Admin', 'email' => 'admin@test.dev', 'password' => 'password', 'role' => 'ADMIN']);

        $this->post('/admin/login', ['email' => $admin->email, 'password' => 'password'])
            ->assertRedirect('/admin');

        $this->get('/admin')->assertOk()->assertSee('Dashboard')->assertSee('BodyCare Admin');
    }

    public function test_guest_is_redirected_to_admin_login(): void
    {
        $this->get('/admin')->assertRedirect('/admin/login');
    }

    public function test_non_admin_cannot_login_to_web_dashboard(): void
    {
        $user = User::create(['name' => 'User', 'email' => 'user@test.dev', 'password' => 'password', 'role' => 'USER']);

        $this->post('/admin/login', ['email' => $user->email, 'password' => 'password'])
            ->assertSessionHasErrors('email');

        $this->assertGuest();
    }

    public function test_non_admin_cannot_open_web_dashboard_directly(): void
    {
        $user = User::create(['name' => 'User', 'email' => 'user-direct@test.dev', 'password' => 'password', 'role' => 'USER']);

        $this->actingAs($user)->get('/admin')->assertForbidden();
    }

    public function test_admin_dashboard_contains_required_metrics_and_menus(): void
    {
        $admin = User::create(['name' => 'Admin', 'email' => 'metrics@test.dev', 'password' => 'password', 'role' => 'ADMIN']);

        $this->actingAs($admin)->get('/admin')
            ->assertOk()
            ->assertSee('Total User')
            ->assertSee('Booking Hari Ini')
            ->assertSee('Booking per Bulan')
            ->assertSee('Pendapatan per Bulan')
            ->assertSee('Layanan Terlaris');

        foreach (['users', 'mitras', 'pelayans', 'services', 'bookings', 'payments', 'reviews', 'notifications', 'reports'] as $section) {
            $this->actingAs($admin)->get("/admin?section={$section}")->assertOk();
        }
    }

    public function test_admin_can_crud_user_and_service(): void
    {
        $admin = User::create(['name' => 'Admin', 'email' => 'crud@test.dev', 'password' => 'password', 'role' => 'ADMIN']);
        $mitraUser = User::create(['name' => 'Mitra', 'email' => 'mitra-crud@test.dev', 'password' => 'password', 'role' => 'MITRA']);
        $mitra = Mitra::create(['user_id' => $mitraUser->id, 'name' => 'Mitra', 'address' => 'Alamat']);

        $this->actingAs($admin)->post('/admin/users', ['name' => 'User Baru', 'email' => 'baru@test.dev', 'password' => 'password', 'status' => 'ACTIVE'])->assertSessionHas('success');
        $user = User::where('email', 'baru@test.dev')->firstOrFail();
        $this->actingAs($admin)->patch("/admin/users/{$user->id}", ['name' => 'User Update', 'email' => $user->email, 'status' => 'SUSPENDED'])->assertSessionHas('success');
        $this->actingAs($admin)->delete("/admin/users/{$user->id}")->assertSessionHas('success');

        $this->actingAs($admin)->post('/admin/services', ['mitra_id' => $mitra->id, 'name' => 'Service Baru', 'category' => 'Spa', 'price' => 100000, 'duration_minutes' => 60, 'is_active' => 1])->assertSessionHas('success');
        $service = Layanan::where('name', 'Service Baru')->firstOrFail();
        $this->actingAs($admin)->delete("/admin/services/{$service->id}")->assertSessionHas('success');
    }
}
