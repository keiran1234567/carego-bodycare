<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Mail\MitraVerificationMail;
use App\Models\Layanan;
use App\Models\Booking;
use App\Models\Mitra;
use App\Models\Pelayan;
use App\Models\Portofolio;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;

class CatalogController extends Controller
{
    public function mitras()
    {
        return ApiResponse::success(Mitra::with('user', 'layanans', 'pelayans.user')->paginate());
    }

    public function mitra(Mitra $mitra)
    {
        return ApiResponse::success($mitra->load('user', 'layanans', 'pelayans.user', 'pelayans.portofolios'));
    }

    public function storeMitra(Request $r)
    {
        $d = $r->validate([
            'user_id' => 'nullable|exists:users,id|unique:mitras,user_id',
            'name' => 'required|string|max:150',
            'email' => 'required_without:user_id|email|unique:users,email',
            'phone' => 'nullable|string|max:25',
            'password' => 'required_without:user_id|string|min:8',
            'address' => 'required|string|max:2000',
            'description' => 'nullable|string|max:2000',
            'open_hours' => 'nullable|string|max:100',
            'is_verified' => 'nullable|boolean',
            'verification_status' => 'nullable|in:pending,approved,rejected',
            'rejection_reason' => 'nullable|string|max:2000',
        ]);

        $mitra = DB::transaction(function () use ($d) {
            $status = $d['verification_status'] ?? (($d['is_verified'] ?? true) ? 'approved' : 'pending');
            $userId = $d['user_id'] ?? \App\Models\User::create([
                'name' => $d['name'],
                'email' => $d['email'],
                'phone' => $d['phone'] ?? null,
                'password' => $d['password'],
                'role' => 'MITRA',
                'status' => $status === 'approved' ? 'ACTIVE' : 'PENDING',
            ])->id;

            return Mitra::create([
                'user_id' => $userId,
                'name' => $d['name'],
                'owner_name' => $d['name'],
                'address' => $d['address'],
                'description' => $d['description'] ?? null,
                'open_hours' => $d['open_hours'] ?? null,
                'is_verified' => $status === 'approved',
                'verification_status' => $status,
                'rejection_reason' => $status === 'rejected' ? ($d['rejection_reason'] ?? null) : null,
                'verified_at' => $status === 'approved' ? now() : null,
            ]);
        });

        return ApiResponse::success($mitra->load('user'), 'Mitra dibuat.', 201);
    }

    public function updateMitra(Request $r, Mitra $mitra)
    {
        $d = $r->validate([
            'name' => 'sometimes|required|string|max:150',
            'email' => 'sometimes|required|email|unique:users,email,'.$mitra->user_id,
            'phone' => 'nullable|string|max:25',
            'password' => 'nullable|string|min:8',
            'address' => 'sometimes|required|string|max:2000',
            'description' => 'nullable|string|max:2000',
            'open_hours' => 'nullable|string|max:100',
            'is_verified' => 'boolean',
            'verification_status' => 'nullable|in:pending,approved,rejected',
            'rejection_reason' => 'nullable|string|max:2000',
            'admin_note' => 'nullable|string|max:2000',
        ]);
        DB::transaction(function () use ($d, $mitra) {
            $userData = collect($d)->only(['name', 'email', 'phone', 'password'])->filter(fn ($value) => $value !== null && $value !== '')->all();
            if ($userData) $mitra->user()->update($userData);
            $mitraData = collect($d)->except(['email', 'phone', 'password'])->all();
            if (array_key_exists('is_verified', $d) && ! array_key_exists('verification_status', $d)) {
                $mitraData['verification_status'] = $d['is_verified'] ? 'approved' : 'pending';
            }
            if (array_key_exists('verification_status', $mitraData)) {
                $mitraData['is_verified'] = $mitraData['verification_status'] === 'approved';
                $mitraData['verified_at'] = $mitraData['verification_status'] === 'approved' ? now() : null;
                if ($mitraData['verification_status'] !== 'rejected') {
                    $mitraData['rejection_reason'] = null;
                }
                $mitra->user()->update([
                    'status' => $mitraData['verification_status'] === 'approved' ? 'ACTIVE' : 'PENDING',
                ]);
            }
            $mitra->update($mitraData);
        });

        return ApiResponse::success($mitra->fresh()->load('user'), 'Mitra diperbarui.');
    }

    public function approveMitra(Mitra $mitra)
    {
        DB::transaction(function () use ($mitra) {
            $mitra->update([
                'is_verified' => true,
                'verification_status' => 'approved',
                'rejection_reason' => null,
                'verified_at' => now(),
            ]);
            $mitra->user()->update(['status' => 'ACTIVE']);
        });

        $this->sendMitraEmail(
            $mitra,
            'Pendaftaran Mitra CareGo Disetujui',
            'Pendaftaran Mitra CareGo Anda telah disetujui. Silakan login dan mulai mengelola layanan.'
        );

        return ApiResponse::success($mitra->fresh()->load('user'), 'Mitra disetujui.');
    }

    public function rejectMitra(Request $request, Mitra $mitra)
    {
        $data = $request->validate([
            'reason' => 'required|string|max:2000',
        ]);

        DB::transaction(function () use ($mitra, $data) {
            $mitra->update([
                'is_verified' => false,
                'verification_status' => 'rejected',
                'rejection_reason' => $data['reason'],
                'verified_at' => null,
            ]);
            $mitra->user()->update(['status' => 'PENDING']);
        });

        $this->sendMitraEmail(
            $mitra,
            'Pendaftaran Mitra CareGo Ditolak',
            "Pendaftaran Mitra CareGo Anda ditolak.\n\nAlasan: {$data['reason']}\n\nSilakan perbaiki data dan ajukan ulang."
        );

        return ApiResponse::success($mitra->fresh()->load('user'), 'Mitra ditolak.');
    }

    public function destroyMitra(Mitra $mitra)
    {
        $user = $mitra->user;
        $user ? $user->delete() : $mitra->delete();

        return ApiResponse::success(null, 'Mitra dihapus.');
    }

    public function pelayans(Request $r)
    {
        $pelayans = Pelayan::with([
            'user',
            'mitra.layanans',
            'portofolios',
            'reviews.user',
            'bookings' => fn ($query) => $query
                ->select('id', 'pelayan_id', 'layanan_id', 'scheduled_at', 'status')
                ->whereNotIn('status', [Booking::DITOLAK_MITRA, Booking::DITOLAK_PELAYAN, Booking::DIBATALKAN, Booking::SELESAI])
                ->where('scheduled_at', '>=', now()),
            'bookings.layanan:id,duration_minutes',
        ])
            ->when($r->user()?->isRole('PELAYAN'), fn ($q) => $q->where('id', $r->user()->pelayan?->id))
            ->when($r->mitra_id, fn ($q, $id) => $q->where('mitra_id', $id))
            ->paginate();

        return ApiResponse::success($pelayans);
    }

    public function pelayan(Pelayan $pelayan)
    {
        return ApiResponse::success($pelayan->load('user', 'mitra.layanans', 'portofolios', 'reviews.user'));
    }

    public function storePelayan(Request $r)
    {
        $d = $r->validate([
            'user_id' => 'nullable|exists:users,id|unique:pelayans,user_id',
            'mitra_id' => 'nullable|exists:mitras,id',
            'name' => 'required_without:user_id|string|max:100',
            'email' => 'required_without:user_id|email|unique:users,email',
            'phone' => 'nullable|string|max:25',
            'password' => 'required_without:user_id|string|min:8',
            'specialization' => 'required|string|max:150',
            'bio' => 'nullable|string|max:2000',
            'experience_years' => 'nullable|integer|min:0',
        ]);
        $mitraId = $r->user()->isRole('MITRA')
            ? $r->user()->mitra->id
            : $d['mitra_id'];

        $pelayan = DB::transaction(function () use ($d, $mitraId) {
            $userId = $d['user_id'] ?? \App\Models\User::create([
                'name' => $d['name'],
                'email' => $d['email'],
                'phone' => $d['phone'] ?? null,
                'password' => $d['password'],
                'role' => 'PELAYAN',
                'status' => 'ACTIVE',
            ])->id;

            return Pelayan::create([
                'user_id' => $userId,
                'mitra_id' => $mitraId,
                'specialization' => $d['specialization'],
                'bio' => $d['bio'] ?? null,
                'experience_years' => $d['experience_years'] ?? 0,
            ])->load('user', 'mitra', 'portofolios');
        });

        return ApiResponse::success($pelayan, 'Pelayan dibuat.', 201);
    }

    public function updatePelayan(Request $r, Pelayan $pelayan)
    {
        $this->ensureMitraOwns($r, $pelayan->mitra_id);
        abort_if($r->user()->isRole('PELAYAN') && $r->user()->id !== $pelayan->user_id, 403, 'Tidak diizinkan mengubah data pelayan lain.');
        $rules = $r->user()->isRole('PELAYAN')
            ? ['is_available' => 'required|boolean']
            : [
                'mitra_id' => 'sometimes|exists:mitras,id',
                'name' => 'sometimes|required|string|max:100',
                'email' => 'sometimes|required|email|unique:users,email,'.$pelayan->user_id,
                'phone' => 'nullable|string|max:25',
                'password' => 'nullable|string|min:8',
                'specialization' => 'sometimes|required|string|max:150',
                'bio' => 'nullable|string|max:2000',
                'experience_years' => 'integer|min:0',
                'is_available' => 'boolean',
            ];
        $d = $r->validate($rules);
        DB::transaction(function () use ($d, $pelayan) {
            $userData = collect($d)->only(['name', 'email', 'phone', 'password'])->filter(fn ($value) => $value !== null && $value !== '')->all();
            if ($userData) $pelayan->user()->update($userData);
            $pelayan->update(collect($d)->except(['name', 'email', 'phone', 'password'])->all());
        });

        return ApiResponse::success($pelayan->fresh()->load('user', 'mitra', 'portofolios'), 'Pelayan diperbarui.');
    }

    public function destroyPelayan(Request $r, Pelayan $pelayan)
    {
        $this->ensureMitraOwns($r, $pelayan->mitra_id);
        $pelayan->user->delete();

        return ApiResponse::success(null, 'Pelayan dihapus.');
    }

    public function layanans(Request $r)
    {
        return ApiResponse::success(Layanan::with('mitra')->when($r->mitra_id, fn ($q, $id) => $q->where('mitra_id', $id))->where('is_active', true)->paginate());
    }

    public function layanan(Layanan $layanan)
    {
        return ApiResponse::success($layanan->load('mitra'));
    }

    public function storeLayanan(Request $r)
    {
        $d = $r->validate(['mitra_id' => 'nullable|exists:mitras,id', 'name' => 'required', 'category' => 'required', 'description' => 'nullable', 'price' => 'required|numeric|min:0', 'duration_minutes' => 'required|integer|min:1', 'image_url' => 'nullable|url']);
        if ($r->user()->isRole('MITRA')) {
            $d['mitra_id'] = $r->user()->mitra->id;
        }

        return ApiResponse::success(Layanan::create($d)->load('mitra'), 'Layanan dibuat.', 201);
    }

    public function updateLayanan(Request $r, Layanan $layanan)
    {
        $this->ensureMitraOwns($r, $layanan->mitra_id);
        $layanan->update($r->validate(['name' => 'sometimes|required', 'category' => 'sometimes|required', 'description' => 'nullable', 'price' => 'numeric|min:0', 'duration_minutes' => 'integer|min:1', 'image_url' => 'nullable|url', 'is_active' => 'boolean']));

        return ApiResponse::success($layanan, 'Layanan diperbarui.');
    }

    public function destroyLayanan(Request $r, Layanan $layanan)
    {
        $this->ensureMitraOwns($r, $layanan->mitra_id);
        $layanan->delete();

        return ApiResponse::success(null, 'Layanan dihapus.');
    }

    public function storePortofolio(Request $r)
    {
        $d = $r->validate(['pelayan_id' => 'required|exists:pelayans,id', 'title' => 'required', 'description' => 'nullable', 'image_url' => 'required|url']);
        $pelayan = Pelayan::findOrFail($d['pelayan_id']);
        abort_if($r->user()->isRole('PELAYAN') && $r->user()->pelayan?->id !== $pelayan->id, 403);
        abort_if($r->user()->isRole('MITRA') && $r->user()->mitra?->id !== $pelayan->mitra_id, 403);

        return ApiResponse::success(Portofolio::create($d), 'Portofolio dibuat.', 201);
    }

    public function destroyPortofolio(Request $r, Portofolio $portofolio)
    {
        abort_if($r->user()->isRole('PELAYAN') && $r->user()->pelayan?->id !== $portofolio->pelayan_id, 403);
        abort_if($r->user()->isRole('MITRA') && $r->user()->mitra?->id !== $portofolio->pelayan->mitra_id, 403);
        $portofolio->delete();

        return ApiResponse::success(null, 'Portofolio dihapus.');
    }

    private function ensureMitraOwns(Request $request, int $mitraId): void
    {
        abort_if($request->user()->isRole('MITRA') && $request->user()->mitra->id !== $mitraId, 403, 'Tidak diizinkan mengubah data mitra lain.');
    }

    private function sendMitraEmail(Mitra $mitra, string $subject, string $body): void
    {
        $email = $mitra->user?->email;
        if (! $email) {
            return;
        }

        Mail::to($email)->send(new MitraVerificationMail($subject, $body));
    }
}
