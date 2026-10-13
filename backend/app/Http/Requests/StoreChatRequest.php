<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreChatRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return ['booking_id' => 'required|exists:bookings,id', 'receiver_id' => 'required|exists:users,id', 'message' => 'required_without:attachment_url|nullable|string|max:3000', 'attachment_url' => 'nullable|url'];
    }
}
