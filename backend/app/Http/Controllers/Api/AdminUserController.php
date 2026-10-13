<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\User;
use Illuminate\Http\Request;

class AdminUserController extends Controller
{
    public function index()
    {
        return ApiResponse::success(User::with('mitra', 'pelayan.mitra')->paginate());
    }

    public function show(User $user)
    {
        return ApiResponse::success($user->load('mitra', 'pelayan.mitra', 'bookings'));
    }

    public function store(Request $request)
    {
        $data = $request->validate(['name' => 'required|string|max:100', 'email' => 'required|email|unique:users', 'phone' => 'nullable|string', 'password' => 'required|min:8', 'role' => 'required|in:USER,MITRA,PELAYAN,ADMIN', 'status' => 'nullable|in:ACTIVE,PENDING,SUSPENDED']);

        return ApiResponse::success(User::create($data), 'User dibuat.', 201);
    }

    public function update(Request $request, User $user)
    {
        $user->update($request->validate(['name' => 'sometimes|required|string|max:100', 'email' => "sometimes|required|email|unique:users,email,{$user->id}", 'phone' => 'nullable|string', 'password' => 'nullable|min:8', 'role' => 'sometimes|in:USER,MITRA,PELAYAN,ADMIN', 'status' => 'sometimes|in:ACTIVE,PENDING,SUSPENDED']));

        return ApiResponse::success($user, 'User diperbarui.');
    }

    public function destroy(User $user)
    {
        $user->delete();

        return ApiResponse::success(null, 'User dihapus.');
    }
}
