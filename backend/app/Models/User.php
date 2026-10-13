<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'phone', 'role', 'status', 'photo_url', 'address', 'wallet_balance',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'wallet_balance' => 'decimal:2',
    ];

    public function mitra()
    {
        return $this->hasOne(Mitra::class);
    }

    public function pelayan()
    {
        return $this->hasOne(Pelayan::class);
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class);
    }

    public function notifications()
    {
        return $this->hasMany(Notifikasi::class);
    }

    public function addresses() { return $this->hasMany(Address::class); }
    public function favorites() { return $this->hasMany(Favorite::class); }
    public function walletTransactions() { return $this->hasMany(WalletTransaction::class); }

    public function isRole(string ...$roles): bool
    {
        return in_array($this->role, array_map('strtoupper', $roles), true);
    }
}
