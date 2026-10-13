<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\Pelayan;
use App\Models\Portofolio;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class MediaController extends Controller
{
    public function profile(Request $request)
    {
        $path = $this->storeBase64($request, 'profiles');
        $request->user()->update(['photo_url' => $this->publicMediaPath($path)]);
        return ApiResponse::success($request->user()->fresh(), 'Foto profil diperbarui.');
    }

    public function portfolio(Request $request)
    {
        $data = $request->validate(['pelayan_id' => 'nullable|exists:pelayans,id', 'title' => 'required|string|max:150', 'description' => 'nullable|string|max:1000']);
        $pelayan = $request->user()->isRole('PELAYAN') ? $request->user()->pelayan : Pelayan::findOrFail($data['pelayan_id']);
        abort_if($request->user()->isRole('MITRA') && $pelayan->mitra_id !== $request->user()->mitra->id, 403);
        $path = $this->storeBase64($request, 'portfolios');
        $portfolio = Portofolio::create([
            'pelayan_id' => $pelayan->id,
            'title' => $data['title'],
            'description' => $data['description'] ?? null,
            'image_url' => $this->publicMediaPath($path),
        ]);
        return ApiResponse::success($portfolio, 'Portofolio ditambahkan.', 201);
    }

    private function storeBase64(Request $request, string $folder): string
    {
        $data = $request->validate(['image_base64' => 'required|string'])['image_base64'];
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
