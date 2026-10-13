<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\Address;
use App\Models\Favorite;
use App\Models\Voucher;
use App\Models\VoucherUsage;
use Illuminate\Http\Request;

class UserFeatureController extends Controller
{
    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'name' => 'sometimes|required|string|max:100',
            'phone' => 'nullable|string|max:25',
            'address' => 'nullable|string|max:1000',
            'photo_url' => 'nullable|url',
        ]);
        $user->update($data);

        return ApiResponse::success($user->fresh()->load('mitra', 'pelayan.mitra'), 'Profil diperbarui.');
    }

    public function addresses(Request $request)
    {
        return ApiResponse::success($request->user()->addresses()->latest('is_primary')->get());
    }

    public function storeAddress(Request $request)
    {
        $data = $request->validate([
            'label' => 'required|string|max:50',
            'address' => 'required|string|max:1000',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'is_primary' => 'boolean',
        ]);
        if ($request->boolean('is_primary')) $request->user()->addresses()->update(['is_primary' => false]);
        $address = $request->user()->addresses()->create($data);
        if ($address->is_primary || ! $request->user()->address) $request->user()->update(['address' => $address->address]);

        return ApiResponse::success($address, 'Alamat ditambahkan.', 201);
    }

    public function updateAddress(Request $request, Address $address)
    {
        abort_unless($address->user_id === $request->user()->id, 403);
        $data = $request->validate([
            'label' => 'sometimes|required|string|max:50',
            'address' => 'sometimes|required|string|max:1000',
            'latitude' => 'sometimes|required|numeric|between:-90,90',
            'longitude' => 'sometimes|required|numeric|between:-180,180',
            'is_primary' => 'boolean',
        ]);
        if ($request->boolean('is_primary')) $request->user()->addresses()->whereKeyNot($address->id)->update(['is_primary' => false]);
        $address->update($data);
        if ($address->is_primary) $request->user()->update(['address' => $address->address]);

        return ApiResponse::success($address, 'Alamat diperbarui.');
    }

    public function destroyAddress(Request $request, Address $address)
    {
        abort_unless($address->user_id === $request->user()->id, 403);
        $address->delete();
        return ApiResponse::success(null, 'Alamat dihapus.');
    }

    public function favorites(Request $request)
    {
        return ApiResponse::success($request->user()->favorites()->with('layanan.mitra', 'mitra')->latest()->get());
    }

    public function storeFavorite(Request $request)
    {
        $data = $request->validate(['layanan_id' => 'nullable|required_without:mitra_id|exists:layanans,id', 'mitra_id' => 'nullable|required_without:layanan_id|exists:mitras,id']);
        $favorite = Favorite::firstOrCreate(['user_id' => $request->user()->id] + $data);
        return ApiResponse::success($favorite->load('layanan.mitra', 'mitra'), 'Favorit disimpan.', 201);
    }

    public function destroyFavorite(Request $request, Favorite $favorite)
    {
        abort_unless($favorite->user_id === $request->user()->id, 403);
        $favorite->delete();
        return ApiResponse::success(null, 'Favorit dihapus.');
    }

    public function vouchers(Request $request)
    {
        $now = now();
        $items = Voucher::where('is_active', true)
            ->where(fn ($q) => $q->whereNull('starts_at')->orWhere('starts_at', '<=', $now))
            ->where(fn ($q) => $q->whereNull('expires_at')->orWhere('expires_at', '>=', $now))
            ->where(fn ($q) => $q->whereNull('quota')->orWhereColumn('used_count', '<', 'quota'))
            ->get();
        return ApiResponse::success($items);
    }

    public function voucherHistory(Request $request)
    {
        return ApiResponse::success(VoucherUsage::with('voucher', 'booking.layanan')->where('user_id', $request->user()->id)->latest()->get());
    }

    public function wallet(Request $request)
    {
        return ApiResponse::success([
            'balance' => $request->user()->wallet_balance,
            'transactions' => $request->user()->walletTransactions()->with('booking.layanan')->latest()->get(),
        ]);
    }
}
