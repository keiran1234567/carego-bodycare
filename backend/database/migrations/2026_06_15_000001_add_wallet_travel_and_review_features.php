<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->decimal('wallet_balance', 14, 2)->default(0)->after('address');
        });
        Schema::table('bookings', function (Blueprint $table) {
            $table->decimal('service_latitude', 10, 7)->nullable()->after('service_address');
            $table->decimal('service_longitude', 10, 7)->nullable()->after('service_latitude');
            $table->decimal('travel_distance_km', 8, 2)->default(0)->after('service_longitude');
            $table->decimal('travel_fee', 14, 2)->default(0)->after('travel_distance_km');
        });
        Schema::table('reviews', function (Blueprint $table) {
            $table->unsignedTinyInteger('mitra_rating')->nullable()->after('rating');
            $table->unsignedTinyInteger('pelayan_rating')->nullable()->after('mitra_rating');
        });
        Schema::create('wallet_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('booking_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('type', ['REFUND', 'DEBIT', 'CREDIT']);
            $table->decimal('amount', 14, 2);
            $table->string('description');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wallet_transactions');
        Schema::table('reviews', fn (Blueprint $table) => $table->dropColumn(['mitra_rating', 'pelayan_rating']));
        Schema::table('bookings', fn (Blueprint $table) => $table->dropColumn(['service_latitude', 'service_longitude', 'travel_distance_km', 'travel_fee']));
        Schema::table('users', fn (Blueprint $table) => $table->dropColumn('wallet_balance'));
    }
};
