<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('mitras', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('logo_url')->nullable();
            $table->string('cover_url')->nullable();
            $table->text('address');
            $table->text('description')->nullable();
            $table->string('open_hours')->nullable();
            $table->decimal('rating', 3, 2)->default(0);
            $table->boolean('is_verified')->default(false);
            $table->timestamps();
        });
        Schema::create('pelayans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignId('mitra_id')->constrained()->cascadeOnDelete();
            $table->string('specialization');
            $table->text('bio')->nullable();
            $table->unsignedInteger('experience_years')->default(0);
            $table->decimal('rating', 3, 2)->default(0);
            $table->boolean('is_available')->default(true);
            $table->timestamps();
        });
        Schema::create('layanans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mitra_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('category');
            $table->text('description')->nullable();
            $table->decimal('price', 14, 2);
            $table->unsignedInteger('duration_minutes');
            $table->string('image_url')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->string('booking_code')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('mitra_id')->constrained();
            $table->foreignId('pelayan_id')->constrained();
            $table->foreignId('layanan_id')->constrained();
            $table->dateTime('scheduled_at');
            $table->text('service_address');
            $table->text('notes')->nullable();
            $table->decimal('total_price', 14, 2);
            $table->string('status')->default('MENUNGGU_PEMBAYARAN');
            $table->text('rejection_reason')->nullable();
            $table->timestamps();
        });
        Schema::create('pembayarans', function (Blueprint $table) {
            $table->id('id_pembayaran');
            $table->foreignId('id_booking')->unique()->constrained('bookings')->cascadeOnDelete();
            $table->string('midtrans_order_id')->unique();
            $table->text('snap_token')->nullable();
            $table->string('metode_pembayaran')->nullable();
            $table->decimal('total_bayar', 14, 2);
            $table->string('status_pembayaran')->default('PENDING');
            $table->decimal('komisi_platform', 14, 2)->default(0);
            $table->decimal('pendapatan_mitra', 14, 2)->default(0);
            $table->decimal('pendapatan_pelayan', 14, 2)->default(0);
            $table->timestamp('waktu_bayar')->nullable();
            $table->json('midtrans_payload')->nullable();
            $table->timestamps();
        });
        Schema::create('reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained();
            $table->foreignId('mitra_id')->constrained();
            $table->foreignId('pelayan_id')->constrained();
            $table->unsignedTinyInteger('rating');
            $table->text('review')->nullable();
            $table->json('photo_urls')->nullable();
            $table->timestamps();
        });
        Schema::create('riwayats', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained()->cascadeOnDelete();
            $table->string('status');
            $table->text('description')->nullable();
            $table->foreignId('changed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
        Schema::create('chats', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained()->cascadeOnDelete();
            $table->foreignId('sender_id')->constrained('users');
            $table->foreignId('receiver_id')->constrained('users');
            $table->text('message');
            $table->string('attachment_url')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
        });
        Schema::create('notifikasis', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('booking_id')->nullable()->constrained()->nullOnDelete();
            $table->string('type');
            $table->string('title');
            $table->text('message');
            $table->json('data')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
        });
        Schema::create('portofolios', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pelayan_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('image_url');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        foreach (['portofolios', 'notifikasis', 'chats', 'riwayats', 'reviews', 'pembayarans', 'bookings', 'layanans', 'pelayans', 'mitras'] as $table) {
            Schema::dropIfExists($table);
        }
    }
};
