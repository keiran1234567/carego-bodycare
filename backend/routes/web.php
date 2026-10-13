<?php

use App\Http\Controllers\AdminWebController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

Route::redirect('/', '/admin');

Route::middleware('guest')->group(function () {
    Route::get('/admin/login', [AdminWebController::class, 'login'])->name('admin.login');
    Route::post('/admin/login', [AdminWebController::class, 'authenticate'])->name('admin.authenticate');
});

Route::middleware('auth')->prefix('admin')->name('admin.')->group(function () {
    Route::get('/', [AdminWebController::class, 'dashboard'])->name('dashboard');
    Route::post('/logout', [AdminWebController::class, 'logout'])->name('logout');
    Route::post('/users', [AdminWebController::class, 'storeUser'])->name('users.store');
    Route::patch('/users/{user}', [AdminWebController::class, 'updateUser'])->name('users.update');
    Route::delete('/users/{user}', [AdminWebController::class, 'destroyUser'])->name('users.destroy');
    Route::post('/mitras', [AdminWebController::class, 'storeMitra'])->name('mitras.store');
    Route::patch('/mitras/{mitra}', [AdminWebController::class, 'updateMitra'])->name('mitras.update');
    Route::delete('/mitras/{mitra}', [AdminWebController::class, 'destroyMitra'])->name('mitras.destroy');
    Route::post('/pelayans', [AdminWebController::class, 'storePelayan'])->name('pelayans.store');
    Route::patch('/pelayans/{pelayan}', [AdminWebController::class, 'updatePelayan'])->name('pelayans.update');
    Route::delete('/pelayans/{pelayan}', [AdminWebController::class, 'destroyPelayan'])->name('pelayans.destroy');
    Route::post('/services', [AdminWebController::class, 'storeService'])->name('services.store');
    Route::patch('/services/{layanan}', [AdminWebController::class, 'updateService'])->name('services.update');
    Route::delete('/services/{layanan}', [AdminWebController::class, 'destroyService'])->name('services.destroy');
    Route::delete('/reviews/{review}', [AdminWebController::class, 'destroyReview'])->name('reviews.destroy');
    Route::delete('/notifications/{notifikasi}', [AdminWebController::class, 'destroyNotification'])->name('notifications.destroy');
    Route::post('/vouchers', [AdminWebController::class, 'storeVoucher'])->name('vouchers.store');
    Route::patch('/vouchers/{voucher}', [AdminWebController::class, 'updateVoucher'])->name('vouchers.update');
    Route::delete('/vouchers/{voucher}', [AdminWebController::class, 'destroyVoucher'])->name('vouchers.destroy');
    Route::patch('/bookings/{booking}/status', [AdminWebController::class, 'updateBooking'])->name('bookings.update');
    Route::get('/reports/export.csv', [AdminWebController::class, 'exportCsv'])->name('reports.csv');
    Route::get('/reports/print', [AdminWebController::class, 'printReport'])->name('reports.print');
});
