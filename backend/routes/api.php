<?php

use App\Http\Controllers\Api\AdminUserController;
use App\Http\Controllers\Api\AdminVoucherController;
use App\Http\Controllers\Api\AdminPaymentController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\InteractionController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\UserFeatureController;
use App\Http\Controllers\Api\MediaController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::prefix('v1')->group(function () {
    Route::post('auth/register', [AuthController::class, 'register']);
    Route::post('auth/login', [AuthController::class, 'login']);
    Route::post('payments/midtrans/callback', [PaymentController::class, 'callback']);
    Route::get('mitras', [CatalogController::class, 'mitras']);
    Route::get('mitras/{mitra}', [CatalogController::class, 'mitra']);
    Route::get('pelayans', [CatalogController::class, 'pelayans']);
    Route::get('pelayans/{pelayan}', [CatalogController::class, 'pelayan']);
    Route::get('layanans', [CatalogController::class, 'layanans']);
    Route::get('layanans/{layanan}', [CatalogController::class, 'layanan']);
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('auth/me', [AuthController::class, 'me']);
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('dashboard', [DashboardController::class, 'index']);
        Route::patch('profile', [UserFeatureController::class, 'updateProfile']);
        Route::post('profile/photo', [MediaController::class, 'profile']);
        Route::get('addresses', [UserFeatureController::class, 'addresses']);
        Route::post('addresses', [UserFeatureController::class, 'storeAddress']);
        Route::patch('addresses/{address}', [UserFeatureController::class, 'updateAddress']);
        Route::delete('addresses/{address}', [UserFeatureController::class, 'destroyAddress']);
        Route::get('favorites', [UserFeatureController::class, 'favorites']);
        Route::post('favorites', [UserFeatureController::class, 'storeFavorite']);
        Route::delete('favorites/{favorite}', [UserFeatureController::class, 'destroyFavorite']);
        Route::get('vouchers', [UserFeatureController::class, 'vouchers']);
        Route::get('voucher-history', [UserFeatureController::class, 'voucherHistory']);
        Route::get('wallet', [UserFeatureController::class, 'wallet'])->middleware('role:USER');
        Route::get('bookings', [BookingController::class, 'index']);
        Route::post('bookings', [BookingController::class, 'store'])->middleware('role:USER');
        Route::get('bookings/{booking}', [BookingController::class, 'show']);
        Route::get('bookings/{booking}/history', [BookingController::class, 'history']);
        Route::patch('bookings/{booking}/status', [BookingController::class, 'updateStatus'])->middleware('role:MITRA,PELAYAN,ADMIN');
        Route::delete('bookings/{booking}', [BookingController::class, 'destroy'])->middleware('role:USER');
        Route::post('bookings/{booking}/payment', [PaymentController::class, 'create'])->middleware('role:USER');
        Route::post('bookings/{booking}/payment/status', [PaymentController::class, 'status'])->middleware('role:USER');
        Route::get('reviews', [InteractionController::class, 'reviews']);
        Route::post('reviews', [InteractionController::class, 'storeReview'])->middleware('role:USER');
        Route::patch('reviews/{review}', [InteractionController::class, 'updateReview'])->middleware('role:USER,ADMIN');
        Route::delete('reviews/{review}', [InteractionController::class, 'destroyReview'])->middleware('role:USER,ADMIN');
        Route::get('bookings/{booking}/chats', [InteractionController::class, 'chats']);
        Route::post('chats', [InteractionController::class, 'storeChat']);
        Route::patch('chats/{chat}', [InteractionController::class, 'updateChat']);
        Route::delete('chats/{chat}', [InteractionController::class, 'destroyChat']);
        Route::get('notifications', [InteractionController::class, 'notifications']);
        Route::patch('notifications/{notifikasi}/read', [InteractionController::class, 'read']);
        Route::delete('notifications/{notifikasi}', [InteractionController::class, 'destroyNotification']);
        Route::get('income', [DashboardController::class, 'income'])->middleware('role:MITRA,PELAYAN');
        Route::patch('pelayans/{pelayan}', [CatalogController::class, 'updatePelayan'])->middleware('role:MITRA,PELAYAN,ADMIN');
        Route::middleware('role:MITRA,ADMIN')->group(function () {
            Route::post('pelayans', [CatalogController::class, 'storePelayan']);
            Route::delete('pelayans/{pelayan}', [CatalogController::class, 'destroyPelayan']);
            Route::post('layanans', [CatalogController::class, 'storeLayanan']);
            Route::patch('layanans/{layanan}', [CatalogController::class, 'updateLayanan']);
            Route::delete('layanans/{layanan}', [CatalogController::class, 'destroyLayanan']);
        });
        Route::middleware('role:PELAYAN,MITRA,ADMIN')->group(function () {
            Route::post('portofolios', [CatalogController::class, 'storePortofolio']);
            Route::post('portofolios/upload', [MediaController::class, 'portfolio']);
            Route::delete('portofolios/{portofolio}', [CatalogController::class, 'destroyPortofolio']);
        });
        Route::middleware('role:ADMIN')->group(function () {
            Route::get('admin/users', [AdminUserController::class, 'index']);
            Route::post('admin/users', [AdminUserController::class, 'store']);
            Route::get('admin/users/{user}', [AdminUserController::class, 'show']);
            Route::patch('admin/users/{user}', [AdminUserController::class, 'update']);
            Route::delete('admin/users/{user}', [AdminUserController::class, 'destroy']);
            Route::post('admin/bookings', [BookingController::class, 'adminStore']);
            Route::delete('admin/bookings/{booking}', [BookingController::class, 'adminDestroy']);
            Route::get('admin/payments', [AdminPaymentController::class, 'index']);
            Route::post('admin/payments', [AdminPaymentController::class, 'store']);
            Route::patch('admin/payments/{pembayaran}', [AdminPaymentController::class, 'update']);
            Route::delete('admin/payments/{pembayaran}', [AdminPaymentController::class, 'destroy']);
            Route::post('notifications', [InteractionController::class, 'storeNotification']);
            Route::post('mitras', [CatalogController::class, 'storeMitra']);
            Route::patch('mitras/{mitra}', [CatalogController::class, 'updateMitra']);
            Route::post('mitras/{mitra}/approve', [CatalogController::class, 'approveMitra']);
            Route::post('mitras/{mitra}/reject', [CatalogController::class, 'rejectMitra']);
            Route::delete('mitras/{mitra}', [CatalogController::class, 'destroyMitra']);
            Route::get('admin/vouchers', [AdminVoucherController::class, 'index']);
            Route::post('admin/vouchers', [AdminVoucherController::class, 'store']);
            Route::patch('admin/vouchers/{voucher}', [AdminVoucherController::class, 'update']);
            Route::delete('admin/vouchers/{voucher}', [AdminVoucherController::class, 'destroy']);
        });
    });
});
