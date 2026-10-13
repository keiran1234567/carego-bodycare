# CareGo Backend API

Laravel 10 REST API untuk frontend Flutter CareGo.

## Menjalankan

```bash
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

Atur koneksi MySQL dan kredensial Midtrans Sandbox pada `.env`. Base URL API adalah `/api/v1`.

## Akun Seeder

Semua password: `password`

- `admin@carego.test`
- `user@carego.test`
- `mitra@carego.test`
- `pelayan@carego.test`

## Response

Semua endpoint mengembalikan struktur `success`, `message`, `data`, dan `errors`. Kirim token Sanctum melalui header `Authorization: Bearer <token>`.

Lihat daftar endpoint dengan:

```bash
php artisan route:list --path=api/v1
```
