<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mitras', function (Blueprint $table) {
            $table->string('owner_name')->nullable()->after('name');
            $table->string('ktp_url')->nullable()->after('cover_url');
            $table->string('verification_status')->default('approved')->after('is_verified');
            $table->text('rejection_reason')->nullable()->after('verification_status');
            $table->timestamp('verified_at')->nullable()->after('rejection_reason');
        });
    }

    public function down(): void
    {
        Schema::table('mitras', function (Blueprint $table) {
            $table->dropColumn([
                'owner_name',
                'ktp_url',
                'verification_status',
                'rejection_reason',
                'verified_at',
            ]);
        });
    }
};
