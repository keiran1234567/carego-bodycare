<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\Voucher;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminVoucherController extends Controller
{
    public function index()
    {
        return ApiResponse::success(Voucher::latest()->paginate());
    }

    public function store(Request $request)
    {
        $voucher = Voucher::create($this->data($request));

        return ApiResponse::success($voucher, 'Voucher dibuat.', 201);
    }

    public function update(Request $request, Voucher $voucher)
    {
        $voucher->update($this->data($request, $voucher));

        return ApiResponse::success($voucher->fresh(), 'Voucher diperbarui.');
    }

    public function destroy(Voucher $voucher)
    {
        abort_if(
            $voucher->usages()->exists(),
            422,
            'Voucher yang sudah digunakan tidak dapat dihapus.'
        );

        $voucher->delete();

        return ApiResponse::success(null, 'Voucher dihapus.');
    }

    private function data(Request $request, ?Voucher $voucher = null): array
    {
        $data = $request->validate([
            'code' => [
                'required',
                'string',
                'max:50',
                Rule::unique('vouchers', 'code')->ignore($voucher?->id),
            ],
            'name' => 'required|string|max:150',
            'description' => 'nullable|string|max:2000',
            'discount_type' => 'required|in:PERCENT,FIXED',
            'discount_value' => 'required|numeric|min:1',
            'max_discount' => 'nullable|numeric|min:0',
            'min_transaction' => 'required|numeric|min:0',
            'quota' => 'nullable|integer|min:1',
            'starts_at' => 'nullable|date',
            'expires_at' => 'nullable|date|after_or_equal:starts_at',
            'is_active' => 'required|boolean',
        ]);
        $data['code'] = strtoupper($data['code']);

        return $data;
    }
}
