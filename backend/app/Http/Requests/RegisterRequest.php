<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => 'required|string|max:100',
            'email' => 'required|email|unique:users,email',
            'phone' => 'nullable|string|max:25',
            'password' => 'required|string|min:8|confirmed',
            'role' => 'required|in:USER,MITRA,PELAYAN,ADMIN',
            'mitra_id' => 'required_if:role,PELAYAN|nullable|exists:mitras,id',
            'business_name' => 'required_if:role,MITRA|nullable|string|max:150',
            'address' => 'required_if:role,MITRA|nullable|string|max:2000',
            'description' => 'required_if:role,MITRA|nullable|string|max:2000',
            'ktp_image_base64' => 'required_if:role,MITRA|nullable|string',
            'logo_image_base64' => 'required_if:role,MITRA|nullable|string',
            'specialization' => 'required_if:role,PELAYAN|nullable|string|max:150',
        ];
    }
}
