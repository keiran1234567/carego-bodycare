<?php

namespace App\Http\Controllers;

use App\Models\Booking;
use App\Models\Layanan;
use App\Models\Mitra;
use App\Models\Notifikasi;
use App\Models\Pelayan;
use App\Models\Pembayaran;
use App\Models\Review;
use App\Models\User;
use App\Models\Voucher;
use App\Services\BookingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AdminWebController extends Controller
{
    public function __construct()
    {
        $this->middleware(function (Request $request, $next) {
            if ($request->routeIs('admin.login', 'admin.authenticate')) return $next($request);
            abort_unless($request->user()?->isRole('ADMIN'), 403);

            return $next($request);
        });
    }

    public function login()
    {
        return Auth::check() && Auth::user()->isRole('ADMIN')
            ? redirect()->route('admin.dashboard')
            : view('admin.login');
    }

    public function authenticate(Request $request)
    {
        $credentials = $request->validate(['email' => 'required|email', 'password' => 'required|string']);
        if (! Auth::attempt($credentials, $request->boolean('remember'))) {
            return back()->withErrors(['email' => 'Email atau password tidak sesuai.'])->onlyInput('email');
        }
        $request->session()->regenerate();
        if (! $request->user()->isRole('ADMIN')) {
            Auth::logout();

            return back()->withErrors(['email' => 'Akun ini bukan akun Admin.']);
        }

        return redirect()->intended(route('admin.dashboard'));
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login');
    }

    public function dashboard(Request $request)
    {
        $section = $request->string('section', 'dashboard')->toString();
        $allowed = ['dashboard', 'users', 'mitras', 'pelayans', 'services', 'bookings', 'vouchers', 'payments', 'reviews', 'notifications', 'reports'];
        if (! in_array($section, $allowed, true)) $section = 'dashboard';

        return view('admin.dashboard', [
            'section' => $section,
            'stats' => $this->stats(),
            'charts' => $this->charts(),
            'recentBookings' => Booking::with('user', 'mitra', 'layanan', 'pembayaran')->latest()->limit(8)->get(),
            'todayBookings' => Booking::with('user', 'mitra', 'layanan')->whereDate('created_at', today())->latest()->limit(5)->get(),
            'users' => $section === 'users' ? User::where('role', 'USER')->latest()->paginate(15)->withQueryString() : collect(),
            'mitras' => $section === 'mitras' ? Mitra::with('user')->withCount('layanans', 'pelayans', 'bookings')->latest()->paginate(15)->withQueryString() : collect(),
            'pelayans' => $section === 'pelayans' ? Pelayan::with('user', 'mitra')->withCount('bookings')->latest()->paginate(15)->withQueryString() : collect(),
            'services' => $section === 'services' ? Layanan::with('mitra')->latest()->paginate(15)->withQueryString() : collect(),
            'bookings' => $section === 'bookings' ? Booking::with('user', 'mitra', 'pelayan.user', 'layanan', 'pembayaran')->latest()->paginate(15)->withQueryString() : collect(),
            'payments' => $section === 'payments' ? Pembayaran::with('booking.user', 'booking.layanan')->latest('id_pembayaran')->paginate(15)->withQueryString() : collect(),
            'reviews' => $section === 'reviews' ? Review::with('user', 'mitra', 'pelayan.user', 'booking')->latest()->paginate(15)->withQueryString() : collect(),
            'notifications' => $section === 'notifications' ? Notifikasi::with('user', 'booking')->latest()->paginate(15)->withQueryString() : collect(),
            'vouchers' => $section === 'vouchers' ? Voucher::latest()->paginate(15)->withQueryString() : collect(),
            'allMitras' => Mitra::orderBy('name')->get(),
            'allUsers' => User::orderBy('name')->get(),
        ]);
    }

    private function stats(): array
    {
        return [
            'users' => User::where('role', 'USER')->count(),
            'mitras' => Mitra::count(),
            'pelayans' => Pelayan::count(),
            'bookings' => Booking::count(),
            'revenue' => Pembayaran::where('status_pembayaran', 'PAID')->sum('total_bayar'),
            'today' => Booking::whereDate('created_at', today())->count(),
            'new_users' => User::where('role', 'USER')->whereMonth('created_at', now()->month)->whereYear('created_at', now()->year)->count(),
            'new_mitras' => Mitra::whereMonth('created_at', now()->month)->whereYear('created_at', now()->year)->count(),
            'new_pelayans' => Pelayan::whereMonth('created_at', now()->month)->whereYear('created_at', now()->year)->count(),
        ];
    }

    private function charts(): array
    {
        $months = collect(range(11, 0))->map(fn ($offset) => now()->subMonths($offset));
        $bookings = $months->map(fn ($month) => Booking::whereYear('created_at', $month->year)->whereMonth('created_at', $month->month)->count());
        $income = $months->map(fn ($month) => (float) Pembayaran::where('status_pembayaran', 'PAID')->whereYear('waktu_bayar', $month->year)->whereMonth('waktu_bayar', $month->month)->sum('total_bayar'));
        $popular = Layanan::withCount('bookings')->orderByDesc('bookings_count')->limit(5)->get(['id', 'name']);

        return [
            'labels' => $months->map(fn ($month) => $month->translatedFormat('M Y')),
            'bookings' => $bookings,
            'income' => $income,
            'popular' => $popular,
        ];
    }

    public function storeUser(Request $request)
    {
        User::create($request->validate([
            'name' => 'required|string|max:100', 'email' => 'required|email|unique:users,email',
            'phone' => 'nullable|string|max:25', 'address' => 'nullable|string|max:1000',
            'password' => 'required|string|min:8', 'status' => 'required|in:ACTIVE,PENDING,SUSPENDED',
        ]) + ['role' => 'USER']);

        return $this->done('User berhasil dibuat.');
    }

    public function updateUser(Request $request, User $user)
    {
        $data = $request->validate([
            'name' => 'required|string|max:100', 'email' => "required|email|unique:users,email,{$user->id}",
            'phone' => 'nullable|string|max:25', 'address' => 'nullable|string|max:1000',
            'status' => 'required|in:ACTIVE,PENDING,SUSPENDED', 'password' => 'nullable|string|min:8',
        ]);
        if (empty($data['password'])) unset($data['password']);
        $user->update($data);

        return $this->done('User berhasil diperbarui.');
    }

    public function destroyUser(Request $request, User $user)
    {
        abort_if($user->id === $request->user()->id, 422, 'Akun Admin aktif tidak dapat dihapus.');
        $user->delete();

        return $this->done('User berhasil dihapus.');
    }

    public function storeMitra(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:150', 'email' => 'required|email|unique:users,email',
            'phone' => 'nullable|string|max:25', 'password' => 'required|string|min:8',
            'address' => 'required|string|max:1000', 'description' => 'nullable|string|max:2000',
            'open_hours' => 'nullable|string|max:100', 'is_verified' => 'required|boolean',
        ]);
        DB::transaction(function () use ($data) {
            $user = User::create(['name' => $data['name'], 'email' => $data['email'], 'phone' => $data['phone'] ?? null, 'password' => $data['password'], 'role' => 'MITRA', 'status' => $data['is_verified'] ? 'ACTIVE' : 'PENDING']);
            Mitra::create(['user_id' => $user->id, 'name' => $data['name'], 'address' => $data['address'], 'description' => $data['description'] ?? null, 'open_hours' => $data['open_hours'] ?? null, 'is_verified' => $data['is_verified']]);
        });

        return $this->done('Mitra berhasil dibuat.');
    }

    public function updateMitra(Request $request, Mitra $mitra)
    {
        $data = $request->validate(['name' => 'required|string|max:150', 'address' => 'required|string|max:1000', 'description' => 'nullable|string|max:2000', 'open_hours' => 'nullable|string|max:100', 'is_verified' => 'required|boolean']);
        $mitra->update($data);
        $mitra->user()->update(['status' => $data['is_verified'] ? 'ACTIVE' : 'PENDING']);

        return $this->done('Mitra berhasil diperbarui.');
    }

    public function destroyMitra(Mitra $mitra)
    {
        $mitra->user->delete();

        return $this->done('Mitra berhasil dihapus.');
    }

    public function storePelayan(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:100', 'email' => 'required|email|unique:users,email',
            'phone' => 'nullable|string|max:25', 'password' => 'required|string|min:8',
            'mitra_id' => 'required|exists:mitras,id', 'specialization' => 'required|string|max:150',
            'bio' => 'nullable|string|max:2000', 'experience_years' => 'required|integer|min:0',
            'is_verified' => 'required|boolean',
        ]);
        DB::transaction(function () use ($data) {
            $user = User::create(['name' => $data['name'], 'email' => $data['email'], 'phone' => $data['phone'] ?? null, 'password' => $data['password'], 'role' => 'PELAYAN', 'status' => $data['is_verified'] ? 'ACTIVE' : 'PENDING']);
            Pelayan::create(['user_id' => $user->id, 'mitra_id' => $data['mitra_id'], 'specialization' => $data['specialization'], 'bio' => $data['bio'] ?? null, 'experience_years' => $data['experience_years']]);
        });

        return $this->done('Pelayan berhasil dibuat.');
    }

    public function updatePelayan(Request $request, Pelayan $pelayan)
    {
        $data = $request->validate(['mitra_id' => 'required|exists:mitras,id', 'specialization' => 'required|string|max:150', 'bio' => 'nullable|string|max:2000', 'experience_years' => 'required|integer|min:0', 'is_available' => 'required|boolean', 'is_verified' => 'required|boolean']);
        $pelayan->update(collect($data)->except('is_verified')->all());
        $pelayan->user()->update(['status' => $data['is_verified'] ? 'ACTIVE' : 'PENDING']);

        return $this->done('Pelayan berhasil diperbarui.');
    }

    public function destroyPelayan(Pelayan $pelayan)
    {
        $pelayan->user->delete();

        return $this->done('Pelayan berhasil dihapus.');
    }

    public function storeService(Request $request)
    {
        Layanan::create($request->validate(['mitra_id' => 'required|exists:mitras,id', 'name' => 'required|string|max:150', 'category' => 'required|string|max:100', 'description' => 'nullable|string|max:2000', 'price' => 'required|numeric|min:1', 'duration_minutes' => 'required|integer|min:1', 'is_active' => 'required|boolean']));

        return $this->done('Layanan berhasil dibuat.');
    }

    public function updateService(Request $request, Layanan $layanan)
    {
        $layanan->update($request->validate(['mitra_id' => 'required|exists:mitras,id', 'name' => 'required|string|max:150', 'category' => 'required|string|max:100', 'description' => 'nullable|string|max:2000', 'price' => 'required|numeric|min:1', 'duration_minutes' => 'required|integer|min:1', 'is_active' => 'required|boolean']));

        return $this->done('Layanan berhasil diperbarui.');
    }

    public function destroyService(Layanan $layanan)
    {
        abort_if($layanan->bookings()->exists(), 422, 'Layanan yang sudah memiliki booking tidak dapat dihapus.');
        $layanan->delete();

        return $this->done('Layanan berhasil dihapus.');
    }

    public function destroyReview(Review $review) { $review->delete(); return $this->done('Review dihapus.'); }
    public function destroyNotification(Notifikasi $notifikasi) { $notifikasi->delete(); return $this->done('Notifikasi dihapus.'); }

    public function storeVoucher(Request $request)
    {
        Voucher::create($this->voucherData($request));
        return $this->done('Voucher berhasil dibuat.');
    }

    public function updateVoucher(Request $request, Voucher $voucher)
    {
        $voucher->update($this->voucherData($request));
        return $this->done('Voucher berhasil diperbarui.');
    }

    public function destroyVoucher(Voucher $voucher)
    {
        abort_if($voucher->usages()->exists(), 422, 'Voucher yang sudah digunakan tidak dapat dihapus.');
        $voucher->delete();
        return $this->done('Voucher berhasil dihapus.');
    }

    public function updateBooking(Request $request, Booking $booking, BookingService $service)
    {
        $data = $request->validate(['status' => 'required|string', 'reason' => 'nullable|string|max:1000']);
        $service->transition($booking, $data['status'], $request->user(), $data['reason'] ?? null);
        return $this->done('Status booking berhasil diperbarui.');
    }

    public function exportCsv()
    {
        $rows = Booking::with('user', 'mitra', 'pelayan.user', 'layanan', 'pembayaran')->latest()->get();
        return response()->streamDownload(function () use ($rows) {
            $out = fopen('php://output', 'w');
            fputcsv($out, ['Kode', 'User', 'Mitra', 'Pelayan', 'Layanan', 'Jadwal', 'Subtotal', 'Diskon', 'Total', 'Status', 'Pembayaran']);
            foreach ($rows as $b) fputcsv($out, [$b->booking_code, $b->user?->name, $b->mitra?->name, $b->pelayan?->user?->name, $b->layanan?->name, $b->scheduled_at, $b->subtotal, $b->discount_amount, $b->total_price, $b->status, $b->pembayaran?->status_pembayaran]);
            fclose($out);
        }, 'carego-report-'.now()->format('Ymd').'.csv', ['Content-Type' => 'text/csv']);
    }

    public function printReport()
    {
        return view('admin.report-print', ['stats' => $this->stats(), 'bookings' => Booking::with('user', 'mitra', 'layanan', 'pembayaran')->latest()->get()]);
    }

    private function voucherData(Request $request): array
    {
        $voucher = $request->route('voucher');
        $data = $request->validate(['code' => ['required','string','max:50',Rule::unique('vouchers','code')->ignore($voucher?->id)], 'name' => 'required|string|max:150', 'description' => 'nullable|string|max:2000', 'discount_type' => 'required|in:PERCENT,FIXED', 'discount_value' => 'required|numeric|min:1', 'max_discount' => 'nullable|numeric|min:0', 'min_transaction' => 'required|numeric|min:0', 'quota' => 'nullable|integer|min:1', 'starts_at' => 'nullable|date', 'expires_at' => 'nullable|date|after_or_equal:starts_at', 'is_active' => 'required|boolean']);
        $data['code'] = strtoupper($data['code']);
        return $data;
    }
    private function done(string $message) { return back()->with('success', $message); }
}
