<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Responses\ApiResponse;
use App\Models\Mitra;
use App\Models\Pelayan;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(RegisterRequest $request)
    {
        $user = DB::transaction(function () use ($request) {
            $data = $request->validated();
            $user = User::create([
                'name' => $data['name'],
                'email' => $data['email'],
                'phone' => $data['phone'] ?? null,
                'password' => $data['password'],
                'role' => $data['role'],
                'status' => $data['role'] === 'MITRA' ? 'PENDING' : 'ACTIVE',
                'address' => $data['address'] ?? null,
            ]);
            if ($user->role === 'MITRA') {
                Mitra::create([
                    'user_id' => $user->id,
                    'name' => $data['business_name'],
                    'owner_name' => $data['name'],
                    'address' => $data['address'],
                    'description' => $data['description'],
                    'ktp_url' => $this->publicMediaPath($this->storeBase64($data['ktp_image_base64'], 'mitra-ktp')),
                    'logo_url' => $this->publicMediaPath($this->storeBase64($data['logo_image_base64'], 'mitra-logos')),
                    'is_verified' => false,
                    'verification_status' => 'pending',
                ]);
            }
            if ($user->role === 'PELAYAN') {
                Pelayan::create(['user_id' => $user->id, 'mitra_id' => $data['mitra_id'], 'specialization' => $data['specialization']]);
            }

            return $user;
        });

        return ApiResponse::success(['user' => $user->load('mitra', 'pelayan.mitra'), 'token' => $user->createToken('carego-mobile')->plainTextToken], 'Registrasi berhasil.', 201);
    }

    public function login(LoginRequest $request)
    {
        $data = $request->validated();
        $identifier = $data['email'];
        $field = filter_var($identifier, FILTER_VALIDATE_EMAIL) ? 'email' : 'phone';
        $credentials = [
            $field => $identifier,
            'password' => $data['password'],
        ];

        if (! empty($data['role'])) {
            $credentials['role'] = $data['role'];
        }

        if (! Auth::attempt($credentials)) {
            return ApiResponse::error('Email/nomor HP atau password tidak sesuai.', null, 401);
        }

        $user = $request->user();

        return ApiResponse::success(['user' => $user->load('mitra', 'pelayan.mitra'), 'token' => $user->createToken('carego-mobile')->plainTextToken], 'Login berhasil.');
    }

    public function me(Request $request)
    {
        return ApiResponse::success($request->user()->load('mitra', 'pelayan.mitra'));
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return ApiResponse::success(null, 'Logout berhasil.');
    }

    private function storeBase64(string $data, string $folder): string
    {
        $data = preg_replace('#^data:image/\w+;base64,#i', '', $data);
        $binary = base64_decode($data, true);
        abort_if($binary === false || strlen($binary) > 5 * 1024 * 1024, 422, 'Gambar tidak valid atau melebihi 5 MB.');
        $path = $folder.'/'.Str::uuid().'.jpg';
        Storage::disk('public')->put($path, $binary);
        return $path;
    }

    private function publicMediaPath(string $path): string
    {
        return '/storage/'.$path;
    }
}
