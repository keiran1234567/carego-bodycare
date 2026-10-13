<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Login Admin - BodyCare</title>
    <style>
        *{box-sizing:border-box}body{margin:0;font-family:Inter,Segoe UI,sans-serif;background:linear-gradient(135deg,#f6f4ff,#eef7ff);color:#17152c;min-height:100vh;display:grid;place-items:center;padding:24px}.card{width:min(430px,100%);background:#fff;border:1px solid #e8e5f2;border-radius:24px;padding:34px;box-shadow:0 24px 70px rgba(57,42,115,.14)}.brand{display:flex;align-items:center;gap:12px;margin-bottom:28px}.logo{width:48px;height:48px;border-radius:16px;background:linear-gradient(135deg,#fa69a6,#7658ef);display:grid;place-items:center;color:white;font-size:25px;font-weight:900}.brand b{font-size:21px}.brand span{display:block;color:#85809a;font-size:12px;margin-top:2px}h1{font-size:27px;margin:0 0 8px}p{color:#77728b;margin:0 0 24px;line-height:1.55}.field{margin-bottom:16px}label{display:block;font-size:13px;font-weight:700;margin-bottom:7px}input{width:100%;border:1px solid #ddd8eb;border-radius:12px;padding:13px 14px;font-size:14px;outline:none}input:focus{border-color:#7257e8;box-shadow:0 0 0 3px #eeeaff}.remember{display:flex;gap:8px;align-items:center;font-size:13px;margin:5px 0 20px}.remember input{width:auto}.btn{border:0;border-radius:12px;background:linear-gradient(135deg,#6a4be2,#8d63ef);color:white;width:100%;padding:14px;font-weight:800;font-size:14px;cursor:pointer}.error{background:#fff1f2;color:#b42335;border-radius:10px;padding:11px 13px;margin-bottom:16px;font-size:13px}.hint{margin-top:20px;padding:13px;background:#f7f6fb;border-radius:12px;font-size:12px;color:#6d687d}.hint b{color:#332c55}
    </style>
</head>
<body>
<main class="card">
    <div class="brand"><div class="logo">B</div><div><b>BodyCare Admin</b><span>Dashboard pengelolaan platform</span></div></div>
    <h1>Selamat datang</h1>
    <p>Masuk menggunakan akun Admin untuk mengelola data aplikasi.</p>
    @if ($errors->any())<div class="error">{{ $errors->first() }}</div>@endif
    <form method="post" action="{{ route('admin.authenticate') }}">
        @csrf
        <div class="field"><label>Email Admin</label><input name="email" type="email" value="{{ old('email') }}" required autofocus></div>
        <div class="field"><label>Password</label><input name="password" type="password" required></div>
        <label class="remember"><input type="checkbox" name="remember" value="1"> Ingat sesi login</label>
        <button class="btn">Masuk ke Dashboard</button>
    </form>
    <div class="hint">Akun demo: <b>admin@carego.test</b> / <b>password</b></div>
</main>
</body>
</html>
