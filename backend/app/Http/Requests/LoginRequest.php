<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => 'required|string|max:150',
            'password' => 'required|string',
            'role' => 'nullable|in:USER,MITRA,PELAYAN,ADMIN',
        ];
    }
}
