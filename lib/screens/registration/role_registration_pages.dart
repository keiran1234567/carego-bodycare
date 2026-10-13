import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/api_client.dart';
import '../../data/app_store.dart';
import '../../models/app_models.dart';
import '../../utils/app_routes.dart';
import '../../widgets/user_ui_widgets.dart';

class EntryRoleSelectionPage extends StatefulWidget {
  const EntryRoleSelectionPage({super.key});

  @override
  State<EntryRoleSelectionPage> createState() => _EntryRoleSelectionPageState();
}

class _EntryRoleSelectionPageState extends State<EntryRoleSelectionPage> {
  AppRole selectedRole = AppRole.user;

  void _continueToLogin() {
    Navigator.pushNamed(context, AppRoutes.login, arguments: selectedRole);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 700;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFF),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _RoleWaveBackground()),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 34, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Peran Anda',
                        style: TextStyle(
                          color: userInk,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Pilih peran yang sesuai untuk\nmelanjutkan ke CareGo',
                        style: TextStyle(
                          color: userMuted,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: compact ? 20 : 28),
                      _EntryRoleCard(
                        role: AppRole.user,
                        icon: Icons.person_rounded,
                        title: 'Saya Pengguna (User)',
                        subtitle:
                            'Booking layanan perawatan\nuntuk diri sendiri atau orang lain',
                        selected: selectedRole == AppRole.user,
                        onTap: () {
                          setState(() => selectedRole = AppRole.user);
                          _continueToLogin();
                        },
                      ),
                      _EntryRoleCard(
                        role: AppRole.mitra,
                        icon: Icons.storefront_rounded,
                        title: 'Saya Mitra',
                        subtitle:
                            'Kelola bisnis, layanan,\npesanan, dan tim Anda',
                        selected: selectedRole == AppRole.mitra,
                        onTap: () {
                          setState(() => selectedRole = AppRole.mitra);
                          _continueToLogin();
                        },
                      ),
                      _EntryRoleCard(
                        role: AppRole.pelayan,
                        icon: Icons.person_rounded,
                        title: 'Saya Pelayan',
                        subtitle:
                            'Bekerja sebagai terapis/beutician\ndan terima pesanan',
                        selected: selectedRole == AppRole.pelayan,
                        onTap: () {
                          setState(() => selectedRole = AppRole.pelayan);
                          _continueToLogin();
                        },
                      ),
                      SizedBox(height: compact ? 8 : 18),
                      const Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                color: userMuted, size: 16),
                            Text(
                              'Peran dapat diubah nanti di pengaturan',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: userMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryRoleCard extends StatelessWidget {
  const _EntryRoleCard({
    required this.role,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final AppRole role;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? userPrimary : const Color(0xFFE7E4F2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF9B6BFF), userPrimary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: userInk,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: userMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Icon(Icons.chevron_right_rounded, color: userPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleWaveBackground extends StatelessWidget {
  const _RoleWaveBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RoleWavePainter());
  }
}

class _RoleWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEDE1FF);
    final path = Path()
      ..moveTo(0, size.height * .9)
      ..cubicTo(size.width * .24, size.height * .84, size.width * .42,
          size.height * .98, size.width * .62, size.height * .93)
      ..cubicTo(size.width * .8, size.height * .88, size.width * .9,
          size.height * .83, size.width, size.height * .82)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RoleRegistrationPage extends StatelessWidget {
  const RoleRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UserPage(
      children: [
        const CustomHeader(title: 'Pilih Pendaftaran'),
        const SizedBox(height: 18),
        const Text(
          'Pilih peran yang ingin Anda daftarkan di BodyCare.',
          textAlign: TextAlign.center,
          style: TextStyle(color: userMuted, height: 1.5),
        ),
        const SizedBox(height: 22),
        _RoleCard(
          icon: Icons.person_outline_rounded,
          title: 'Pelanggan',
          subtitle: 'Booking layanan body care untuk datang ke rumah.',
          onTap: () => Navigator.pushNamed(context, AppRoutes.register),
        ),
        _RoleCard(
          icon: Icons.storefront_outlined,
          title: 'Mitra / Salon',
          subtitle:
              'Daftarkan bisnis, kelola layanan, pelayan, dan pesanan pelanggan.',
          onTap: () => Navigator.pushNamed(context, AppRoutes.partnerRegister),
        ),
        _RoleCard(
          icon: Icons.badge_outlined,
          title: 'Pelayan / Karyawan',
          subtitle:
              'Pelayan wajib bergabung dengan Mitra untuk dapat menerima tugas.',
          onTap: () => Navigator.pushNamed(context, AppRoutes.employeeRegister),
        ),
        const SoftCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: userPrimary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pelayan tidak dapat bekerja mandiri. Pendaftaran Pelayan harus disetujui oleh Mitra atau menggunakan kode undangan dari Mitra.',
                  style: TextStyle(color: userMuted, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PartnerRegistrationPage extends StatefulWidget {
  const PartnerRegistrationPage({super.key});

  @override
  State<PartnerRegistrationPage> createState() =>
      _PartnerRegistrationPageState();
}

class _PartnerRegistrationPageState extends State<PartnerRegistrationPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final businessNameController = TextEditingController();
  final addressController = TextEditingController();
  final descriptionController = TextEditingController();
  final picker = ImagePicker();
  XFile? ktpImage;
  XFile? logoImage;
  var submitting = false;

  Future<void> _register() async {
    if (nameController.text.trim().isEmpty ||
        businessNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.length < 8 ||
        addressController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        ktpImage == null ||
        logoImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua data mitra, termasuk KTP dan logo.'),
        ),
      );
      return;
    }
    setState(() => submitting = true);
    try {
      final ktpBase64 = base64Encode(await ktpImage!.readAsBytes());
      final logoBase64 = base64Encode(await logoImage!.readAsBytes());
      await AppStore.instance.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
        role: AppRole.mitra,
        businessName: businessNameController.text.trim(),
        address: addressController.text.trim(),
        description: descriptionController.text.trim(),
        ktpImageBase64: ktpBase64,
        logoImageBase64: logoBase64,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.registrationStatus, (_) => false);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    businessNameController.dispose();
    addressController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool ktp) async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (image == null || !mounted) return;
    setState(() {
      if (ktp) {
        ktpImage = image;
      } else {
        logoImage = image;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return UserPage(
      bottom: BottomActionBar(
        primaryLabel:
            submitting ? 'Mendaftarkan...' : 'Kirim Pendaftaran Mitra',
        onPrimary: submitting ? () {} : _register,
      ),
      children: [
        const CustomHeader(title: 'Daftar Mitra'),
        const SizedBox(height: 12),
        const _ProgressHeader(
            step: 1, labels: ['Data Pemilik', 'Data Usaha', 'Verifikasi']),
        const SizedBox(height: 20),
        const SectionTitle(title: 'Data Pemilik'),
        _RegistrationField(
            label: 'Nama lengkap',
            icon: Icons.person_outline_rounded,
            controller: nameController),
        _RegistrationField(
            label: 'Nomor telepon',
            icon: Icons.phone_outlined,
            controller: phoneController),
        _RegistrationField(
            label: 'Email',
            icon: Icons.mail_outline_rounded,
            controller: emailController),
        _RegistrationField(
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            controller: passwordController,
            obscure: true),
        const SectionTitle(title: 'Data Usaha'),
        _RegistrationField(
            label: 'Nama salon / mitra',
            icon: Icons.storefront_outlined,
            controller: businessNameController),
        _RegistrationField(
            label: 'Alamat usaha',
            icon: Icons.location_on_outlined,
            controller: addressController,
            lines: 3),
        const _RegistrationField(
            label: 'Jam operasional', icon: Icons.schedule_outlined),
        _RegistrationField(
            label: 'Deskripsi usaha',
            icon: Icons.notes_outlined,
            controller: descriptionController,
            lines: 4),
        const SectionTitle(title: 'Dokumen Verifikasi'),
        _UploadTile(
          label: 'Foto KTP Pemilik',
          image: ktpImage,
          onTap: () => _pickImage(true),
        ),
        _UploadTile(
          label: 'Foto Profil / Logo Usaha',
          image: logoImage,
          onTap: () => _pickImage(false),
        ),
      ],
    );
  }
}

class EmployeeRegistrationPage extends StatefulWidget {
  const EmployeeRegistrationPage({super.key});

  @override
  State<EmployeeRegistrationPage> createState() =>
      _EmployeeRegistrationPageState();
}

class _EmployeeRegistrationPageState extends State<EmployeeRegistrationPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final specializationController = TextEditingController();
  String? selectedMitraId;
  var submitting = false;

  Future<void> _register() async {
    if (selectedMitraId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih Mitra terlebih dahulu.')),
      );
      return;
    }
    setState(() => submitting = true);
    try {
      await AppStore.instance.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
        role: AppRole.pelayan,
        mitraId: selectedMitraId,
        specialization: specializationController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.employeeDashboard, (_) => false);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    specializationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mitras = AppStore.instance.mitras;
    selectedMitraId ??= mitras.isEmpty ? null : mitras.first.id;

    return UserPage(
      bottom: BottomActionBar(
        primaryLabel:
            submitting ? 'Mendaftarkan...' : 'Kirim Pendaftaran Pelayan',
        onPrimary: submitting ? () {} : _register,
      ),
      children: [
        const CustomHeader(title: 'Daftar Pelayan'),
        const SizedBox(height: 12),
        const SoftCard(
          child: Row(
            children: [
              Icon(Icons.storefront_outlined, color: userPrimary, size: 32),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Pelayan wajib mempunyai Mitra aktif. Pilih Mitra atau gunakan kode undangan untuk melanjutkan.',
                  style: TextStyle(color: userMuted, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle(title: 'Data Pelayan'),
        _RegistrationField(
            label: 'Nama lengkap',
            icon: Icons.person_outline_rounded,
            controller: nameController),
        _RegistrationField(
            label: 'Nomor telepon',
            icon: Icons.phone_outlined,
            controller: phoneController),
        _RegistrationField(
            label: 'Email',
            icon: Icons.mail_outline_rounded,
            controller: emailController),
        _RegistrationField(
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            controller: passwordController,
            obscure: true),
        _RegistrationField(
            label: 'Spesialisasi',
            icon: Icons.spa_outlined,
            controller: specializationController),
        const _RegistrationField(
            label: 'Pengalaman kerja', icon: Icons.workspace_premium_outlined),
        const SectionTitle(title: 'Pilih Mitra'),
        DropdownButtonFormField<String>(
          initialValue: selectedMitraId,
          items: mitras
              .map((mitra) => DropdownMenuItem(
                    value: mitra.id,
                    child: Text(mitra.name),
                  ))
              .toList(),
          onChanged: (value) => setState(() => selectedMitraId = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.storefront_outlined, color: userPrimary),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        _JoinMethodCard(
          icon: Icons.key_rounded,
          title: 'Gunakan Kode Undangan',
          subtitle: 'Masukkan kode yang diberikan oleh Mitra.',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.partnerInviteCode),
        ),
      ],
    );
  }
}

class SelectPartnerPage extends StatefulWidget {
  const SelectPartnerPage({super.key});

  @override
  State<SelectPartnerPage> createState() => _SelectPartnerPageState();
}

class _SelectPartnerPageState extends State<SelectPartnerPage> {
  var selected = 0;

  @override
  Widget build(BuildContext context) {
    const partners = [
      ('Glow Beauty Home Service', 'Jakarta Selatan', '4.8', '12 Pelayan'),
      ('Elegance Salon Home Service', 'Jakarta Timur', '4.7', '8 Pelayan'),
      ('Care Studio Home Service', 'Jakarta Barat', '4.9', '15 Pelayan'),
    ];
    return UserPage(
      bottom: BottomActionBar(
        primaryLabel: 'Kirim Permintaan Bergabung',
        onPrimary: () =>
            Navigator.pushNamed(context, AppRoutes.registrationStatus),
      ),
      children: [
        const CustomHeader(title: 'Pilih Mitra'),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            hintText: 'Cari nama mitra atau lokasi...',
            prefixIcon: Icon(Icons.search_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(partners.length, (index) {
          final item = partners[index];
          final active = selected == index;
          return InkWell(
            onTap: () => setState(() => selected = index),
            borderRadius: BorderRadius.circular(14),
            child: SoftCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFF0EDFF),
                    child: Text(item.$1.characters.first,
                        style: const TextStyle(
                            color: userPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$1,
                            style: const TextStyle(
                                color: userInk, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('${item.$2}  •  Rating ${item.$3}',
                            style: const TextStyle(color: userMuted)),
                        const SizedBox(height: 4),
                        Text(item.$4, style: const TextStyle(color: userMuted)),
                      ],
                    ),
                  ),
                  Icon(
                    active
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: active ? userPrimary : userMuted,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class PartnerInviteCodePage extends StatelessWidget {
  const PartnerInviteCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return UserPage(
      children: [
        const CustomHeader(title: 'Kode Undangan Mitra'),
        const SizedBox(height: 28),
        const Icon(Icons.mark_email_read_outlined,
            size: 82, color: userPrimary),
        const SizedBox(height: 20),
        const Text(
          'Masukkan kode undangan',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: userInk, fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kode diberikan oleh Mitra yang mengundang Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(color: userMuted),
        ),
        const SizedBox(height: 24),
        const TextField(
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'Contoh: GLOW-2026-AB12',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.registrationStatus),
            style: FilledButton.styleFrom(backgroundColor: userPrimary),
            child: const Text('Verifikasi Kode & Bergabung'),
          ),
        ),
      ],
    );
  }
}

class RegistrationStatusPage extends StatefulWidget {
  const RegistrationStatusPage({super.key});

  @override
  State<RegistrationStatusPage> createState() => _RegistrationStatusPageState();
}

class _RegistrationStatusPageState extends State<RegistrationStatusPage> {
  var refreshing = false;

  Future<void> _refreshStatus() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    try {
      await AppStore.instance.refreshSession(refreshData: true);
      if (!mounted) return;
      final mitra = AppStore.instance.currentMitra;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mitra?.isApproved == true
                ? 'Pendaftaran disetujui. Dashboard Mitra sudah aktif.'
                : mitra?.isRejected == true
                    ? 'Pendaftaran ditolak. Cek alasan penolakan.'
                    : 'Status terbaru: masih menunggu verifikasi admin.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  Future<void> _backToLogin() async {
    await AppStore.instance.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
      arguments: AppRole.mitra,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mitra = AppStore.instance.currentMitra;
    final rejected = mitra?.isRejected ?? false;
    final approved = mitra?.isApproved ?? false;
    return UserPage(
      children: [
        CustomHeader(
          title: 'Status Pendaftaran',
          onBack: _backToLogin,
          trailing: IconButton(
            tooltip: 'Refresh status',
            onPressed: refreshing ? null : _refreshStatus,
            icon: refreshing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Icon(Icons.refresh_rounded, color: userPrimary),
          ),
        ),
        const SizedBox(height: 28),
        SoftCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: approved
                    ? const Color(0xFFE8F7EF)
                    : const Color(0xFFFFF4D9),
                child: Icon(
                  approved
                      ? Icons.verified_rounded
                      : rejected
                          ? Icons.cancel_rounded
                          : Icons.hourglass_top_rounded,
                  color: approved
                      ? const Color(0xFF21A66D)
                      : rejected
                          ? const Color(0xFFE24A4A)
                          : const Color(0xFFE09A16),
                  size: 48,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                  approved
                      ? 'Pendaftaran Disetujui'
                      : rejected
                          ? 'Pendaftaran Ditolak'
                          : 'Menunggu Verifikasi Admin',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: userInk,
                      fontSize: 21,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(
                approved
                    ? 'Akun mitra Anda sudah aktif. Silakan masuk ke dashboard.'
                    : rejected
                        ? 'Alasan: ${mitra?.rejectionReason.isEmpty == true ? 'Silakan perbaiki data dan ajukan ulang.' : mitra?.rejectionReason}'
                        : 'Data pendaftaran mitra Anda sudah tersimpan dan sedang diperiksa admin CareGo. Informasi diterima atau ditolak akan dikirim ke email terdaftar.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: userMuted, height: 1.5),
              ),
              if (approved) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.partnerDashboard,
                    (_) => false,
                  ),
                  child: const Text('Buka Dashboard Mitra'),
                ),
              ],
            ],
          ),
        ),
        const SectionTitle(title: 'Proses Pendaftaran'),
        const SoftCard(
          child: Column(
            children: [
              _StatusStep('Data mitra dikirim', true),
              _StatusStep('Admin meninjau dokumen', true),
              _StatusStep('Verifikasi admin', false),
              _StatusStep('Akun mitra aktif', false),
            ],
          ),
        ),
        const SoftCard(
          child: Text(
            'Dashboard Mitra hanya dapat digunakan setelah admin menyetujui pendaftaran.',
            style: TextStyle(color: userMuted, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class PartnerInviteEmployeePage extends StatelessWidget {
  const PartnerInviteEmployeePage({super.key});

  @override
  Widget build(BuildContext context) {
    return UserPage(
      bottom: BottomActionBar(
        primaryLabel: 'Kirim Undangan Pelayan',
        onPrimary: () => Navigator.pop(context),
      ),
      children: const [
        CustomHeader(title: 'Undang Pelayan'),
        SizedBox(height: 16),
        SoftCard(
          child: Text(
            'Undangan akan menghubungkan akun Pelayan langsung dengan Glow Beauty Home Service setelah diterima.',
            style: TextStyle(color: userMuted, height: 1.5),
          ),
        ),
        _RegistrationField(
            label: 'Nama pelayan', icon: Icons.person_outline_rounded),
        _RegistrationField(
            label: 'Email pelayan', icon: Icons.mail_outline_rounded),
        _RegistrationField(label: 'Nomor telepon', icon: Icons.phone_outlined),
        _RegistrationField(label: 'Spesialisasi', icon: Icons.spa_outlined),
        SectionTitle(title: 'Kode Undangan'),
        SoftCard(
          child: Row(
            children: [
              Expanded(
                child: Text('GLOW-2026-AB12',
                    style: TextStyle(
                        color: userPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
              ),
              Icon(Icons.copy_rounded, color: userPrimary),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SoftCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFF0EDFF),
                child: Icon(icon, color: userPrimary, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: userInk,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: const TextStyle(color: userMuted, height: 1.4)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: userMuted),
            ],
          ),
        ),
      );
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step, required this.labels});
  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(
          labels.length,
          (index) => Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      index < step ? userPrimary : const Color(0xFFE8E8F1),
                  child: Text('${index + 1}',
                      style: TextStyle(
                          color: index < step ? Colors.white : userMuted)),
                ),
                const SizedBox(height: 6),
                Text(labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: userMuted)),
              ],
            ),
          ),
        ),
      );
}

class _RegistrationField extends StatelessWidget {
  const _RegistrationField(
      {required this.label,
      required this.icon,
      this.lines = 1,
      this.controller,
      this.obscure = false});
  final String label;
  final IconData icon;
  final int lines;
  final TextEditingController? controller;
  final bool obscure;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          minLines: lines,
          maxLines: lines,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: userPrimary),
            border: const OutlineInputBorder(),
          ),
        ),
      );
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.label, this.image, this.onTap});
  final String label;
  final XFile? image;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SoftCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: image == null
                    ? const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.upload_file_outlined,
                            color: userPrimary),
                      )
                    : Image.file(
                        File(image!.path),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: userInk, fontWeight: FontWeight.w800)),
              ),
              const Text('Upload',
                  style: TextStyle(
                      color: userPrimary, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );
}

class _JoinMethodCard extends StatelessWidget {
  const _JoinMethodCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      _RoleCard(icon: icon, title: title, subtitle: subtitle, onTap: onTap);
}

class _StatusStep extends StatelessWidget {
  const _StatusStep(this.label, this.done);
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: done ? const Color(0xFF21A66D) : userMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: userInk, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}
