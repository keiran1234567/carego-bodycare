import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/app_store.dart';
import '../utils/app_routes.dart';
import '../utils/app_theme.dart';
import '../widgets/bottom_navs.dart';

const _profileBlue = Color(0xFF225CD8);
const _profileLine = Color(0xFFE7E9F0);
const _profileMuted = Color(0xFF747985);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'User';
    if (role != 'User') {
      return _RoleProfile(role: role);
    }

    return Theme(
      data: buildRoleBlueTheme(
        Theme.of(context),
        primary: _profileBlue,
        secondary: const Color(0xFF4D77F6),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFCFE),
        bottomNavigationBar: const UserBottomNav(currentIndex: 3),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: const [
                  _ProfileHeader(),
                  SizedBox(height: 18),
                  _IdentityCard(),
                  SizedBox(height: 14),
                  _OrdersCard(),
                  SizedBox(height: 14),
                  _MemberCard(),
                  SizedBox(height: 20),
                  Text('Menu Akun',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                  SizedBox(height: 10),
                  _AccountMenu(),
                  SizedBox(height: 16),
                  _ReferralCard(),
                  SizedBox(height: 16),
                  _LogoutButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profil',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              SizedBox(height: 4),
              Text('Kelola akun dan informasi Anda',
                  style: TextStyle(fontSize: 12, color: _profileMuted)),
            ],
          ),
        ),
        IconButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.userNotifications),
          icon: const Icon(Icons.notifications_none_rounded, size: 28),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.settings_outlined, size: 27),
      ],
    );
  }
}

class _IdentityCard extends StatefulWidget {
  const _IdentityCard();

  @override
  State<_IdentityCard> createState() => _IdentityCardState();
}

class _IdentityCardState extends State<_IdentityCard> {
  var uploading = false;

  @override
  Widget build(BuildContext context) {
    final user = AppStore.instance.currentUser;
    final phone = user?.phone.isNotEmpty == true ? user!.phone : 'Belum diatur';
    final email = user?.email.isNotEmpty == true ? user!.email : 'Belum diatur';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFDCE7FF), Color(0xFFF1F3FF)]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white,
                backgroundImage: user?.photoUrl.isNotEmpty == true
                    ? NetworkImage(user!.photoUrl)
                    : null,
                child: user?.photoUrl.isNotEmpty == true
                    ? null
                    : const Icon(Icons.person_rounded,
                        size: 58, color: _profileBlue),
              ),
              Positioned(
                right: -2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                      color: _profileBlue, shape: BoxShape.circle),
                  child: InkWell(
                    onTap: uploading ? null : _pickPhoto,
                    child: uploading
                        ? const SizedBox.square(
                            dimension: 13,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.camera_alt_outlined,
                            size: 13, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, ${user?.name ?? 'User'}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 7),
                Text(phone, style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 5),
                Text(email, style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 11),
                const Text('Akun User',
                    style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF3E5C8E),
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            width: 120,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(9)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Akun',
                    style: TextStyle(fontSize: 9, color: _profileMuted)),
                const SizedBox(height: 13),
                const Text('Aktif',
                    style: TextStyle(
                        fontSize: 17,
                        color: _profileBlue,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 13),
                SizedBox(
                  height: 32,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.bookingHistory),
                    style: FilledButton.styleFrom(
                        backgroundColor: _profileBlue,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6))),
                    child:
                        const Text('Riwayat', style: TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1200,
    );
    if (file == null) return;
    setState(() => uploading = true);
    try {
      await AppStore.instance
          .uploadProfilePhoto(base64Encode(await file.readAsBytes()));
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }
}

class _OrdersCard extends StatelessWidget {
  const _OrdersCard();

  @override
  Widget build(BuildContext context) {
    final bookings = AppStore.instance.bookings;
    final data = [
      (
        'Menunggu',
        Icons.schedule_rounded,
        bookings
            .where((item) =>
                item.status == 'Menunggu Pembayaran' ||
                item.status == 'Menunggu Mitra')
            .length
            .toString()
      ),
      (
        'Dikerjakan',
        Icons.delivery_dining_rounded,
        bookings
            .where((item) =>
                item.status != 'Menunggu Pembayaran' &&
                item.status != 'Menunggu Mitra' &&
                item.status != 'Selesai' &&
                item.status != 'Dibatalkan')
            .length
            .toString()
      ),
      (
        'Selesai',
        Icons.check_circle_outline_rounded,
        bookings.where((item) => item.status == 'Selesai').length.toString()
      ),
      (
        'Diberi Rating',
        Icons.star_outline_rounded,
        AppStore.instance.reviews.length.toString()
      ),
      (
        'Dibatalkan',
        Icons.cancel_outlined,
        bookings.where((item) => item.status == 'Dibatalkan').length.toString()
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 15),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _profileLine),
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                  child: Text('Pesanan Saya',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w900))),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.bookingHistory),
                child: const Text('Lihat Semua  >',
                    style: TextStyle(fontSize: 9, color: _profileBlue)),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: data.map((item) {
              return Expanded(
                child: InkWell(
                  onTap: () {
                    final route = switch (item.$1) {
                      'Dikerjakan' => AppRoutes.userTracking,
                      'Selesai' => AppRoutes.bookingDetail,
                      'Diberi Rating' => AppRoutes.userReview,
                      _ => AppRoutes.bookingHistory,
                    };
                    Navigator.pushNamed(context, route);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    children: [
                      Icon(item.$2,
                          color: item.$1 == 'Selesai'
                              ? const Color(0xFF25A777)
                              : const Color(0xFF252A34),
                          size: 24),
                      const SizedBox(height: 8),
                      Text(item.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 8.5)),
                      const SizedBox(height: 4),
                      CircleAvatar(
                          radius: 7,
                          backgroundColor: _profileBlue,
                          child: Text(item.$3,
                              style: const TextStyle(
                                  fontSize: 7, color: Colors.white))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFE9EEFF),
          borderRadius: BorderRadius.circular(10)),
      child: const Row(
        children: [
          CircleAvatar(
              radius: 39,
              backgroundColor: Colors.white,
              child: Icon(Icons.diamond_outlined,
                  size: 40, color: Color(0xFF3E5C8E))),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Member Silver',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Dapatkan lebih banyak keuntungan\ndari setiap pemesanan',
                    style: TextStyle(
                        fontSize: 9, color: _profileMuted, height: 1.4)),
                SizedBox(height: 9),
                LinearProgressIndicator(
                    value: .32,
                    minHeight: 5,
                    color: _profileBlue,
                    backgroundColor: Color(0xFFD9E0F6),
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                SizedBox(height: 5),
                Text('320 / 1.000 poin menuju Gold',
                    style: TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
          SizedBox(width: 12),
          OutlinedButton(
            onPressed: null,
            style: ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size(92, 36)),
            ),
            child: Text('Lihat Benefit',
                style: TextStyle(fontSize: 9, color: _profileBlue)),
          ),
        ],
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Profil Saya', Icons.person_outline_rounded),
      ('Alamat API Server', Icons.dns_outlined),
      ('Favorit Saya', Icons.favorite_border_rounded),
      ('Dompet & Riwayat Refund', Icons.account_balance_wallet_outlined),
      ('Alamat Saya', Icons.location_on_outlined),
      ('Metode Pembayaran', Icons.credit_card_outlined),
      ('Promo & Voucher', Icons.discount_outlined),
      ('Riwayat Transaksi', Icons.receipt_long_outlined),
      ('Bantuan & Pusat Bantuan', Icons.headset_mic_outlined),
      ('Tentang BodyCare', Icons.info_outline_rounded),
      ('Demo Empty State', Icons.inbox_outlined),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _profileLine),
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: items.map((item) {
          return InkWell(
            onTap: () {
              final route = switch (item.$1) {
                'Favorit Saya' => AppRoutes.userFavorites,
                'Dompet & Riwayat Refund' => AppRoutes.userWallet,
                'Alamat Saya' => AppRoutes.addresses,
                'Metode Pembayaran' => AppRoutes.paymentMethods,
                'Promo & Voucher' => AppRoutes.promoVoucher,
                'Bantuan & Pusat Bantuan' => AppRoutes.helpCenter,
                'Tentang BodyCare' => AppRoutes.aboutBodyCare,
                'Demo Empty State' => AppRoutes.userEmptyStates,
                _ => null,
              };
              if (item.$1 == 'Profil Saya') {
                _showEditProfile(context);
                return;
              }
              if (item.$1 == 'Alamat API Server') {
                _showApiServerDialog(context);
                return;
              }
              if (route != null) {
                Navigator.pushNamed(context, route);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF0F1F5)))),
              child: Row(
                children: [
                  Icon(item.$2, size: 17, color: _profileBlue),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(item.$1,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600))),
                  const Icon(Icons.chevron_right_rounded,
                      color: _profileMuted, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

Future<void> _showEditProfile(BuildContext context) async {
  final store = AppStore.instance;
  final user = store.currentUser;
  if (user == null) return;
  final name = TextEditingController(text: user.name);
  final phone = TextEditingController(text: user.phone);
  final address = TextEditingController(text: user.address);
  final save = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Profil Saya'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama')),
            const SizedBox(height: 12),
            TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nomor telepon')),
            const SizedBox(height: 12),
            TextField(
                controller: address,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Alamat utama')),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan')),
      ],
    ),
  );
  if (save == true && name.text.trim().isNotEmpty) {
    await store.updateProfile(
        name: name.text.trim(),
        phone: phone.text.trim(),
        address: address.text.trim());
  }
}

Future<void> _showApiServerDialog(BuildContext context) async {
  final rootContext = context;
  final store = AppStore.instance;
  final controller = TextEditingController(text: store.apiBaseUrl);
  var saving = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Alamat API Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contoh: 192.168.18.81:8000 atau http://192.168.18.81:8000/api/v1',
              style: TextStyle(fontSize: 12, color: _profileMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Alamat API'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setDialogState(() => saving = true);
                    try {
                      await store.updateApiBaseUrl(controller.text);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Alamat API diperbarui ke ${store.apiBaseUrl}',
                          ),
                        ),
                      );
                    } catch (error) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text('$error')),
                      );
                      setDialogState(() => saving = false);
                    }
                  },
            child: Text(saving ? 'Menyimpan...' : 'Simpan'),
          ),
        ],
      ),
    ),
  );
}

class _ReferralCard extends StatelessWidget {
  const _ReferralCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFFF0F3FF),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ajak Teman, Dapat Reward!',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text(
                    'Dapatkan saldo wallet hingga Rp50.000\nuntuk setiap teman yang bergabung.',
                    style: TextStyle(
                        fontSize: 9, color: _profileMuted, height: 1.5)),
                const SizedBox(height: 14),
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                        backgroundColor: _profileBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 17),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6))),
                    child: const Text('Ajak Sekarang',
                        style: TextStyle(fontSize: 9)),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.card_giftcard_rounded,
              color: Color(0xFFFFC93C), size: 74),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirmLogout(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red.shade700,
        side: BorderSide(color: Colors.red.shade200),
        minimumSize: const Size.fromHeight(48),
      ),
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Keluar dari akun'),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu login kembali untuk menggunakan akun.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await AppStore.instance.logout();
    } catch (_) {
      // The local session is cleared even when the backend is unreachable.
    }
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelection,
      (_) => false,
    );
  }
}

class _RoleProfile extends StatelessWidget {
  const _RoleProfile({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    const menus = [
      ('Informasi Mitra', Icons.storefront_outlined),
      ('Layanan & Harga', Icons.spa_outlined),
      ('Jam Operasional', Icons.schedule_outlined),
      ('Rekening Pencairan', Icons.account_balance_outlined),
      ('Pengaturan Akun', Icons.settings_outlined),
      ('Bantuan Mitra', Icons.headset_mic_outlined),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      bottomNavigationBar:
          role == 'Mitra' ? const PartnerBottomNav(currentIndex: 3) : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                Row(children: [
                  Expanded(
                    child: Text('Profil $role',
                        style: const TextStyle(
                            fontSize: 25, fontWeight: FontWeight.w900)),
                  ),
                  IconButton.filledTonal(
                      onPressed: () => _showEditProfile(context),
                      icon: const Icon(Icons.edit_outlined)),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF3156D3), Color(0xFF6941D9)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(children: [
                    CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.spa_rounded,
                            size: 40, color: Color(0xFF6941D9))),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Glow Beauty Home Service',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900)),
                          SizedBox(height: 5),
                          Text('Mitra terverifikasi • Rating 4.8',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                          SizedBox(height: 9),
                          Text('Jakarta Selatan',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _profileLine),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Row(children: [
                    Expanded(child: _RoleMetric(value: '12', label: 'Pelayan')),
                    Expanded(child: _RoleMetric(value: '24', label: 'Layanan')),
                    Expanded(
                        child: _RoleMetric(value: '128', label: 'Booking')),
                  ]),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _profileLine),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: menus
                        .map((item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFF1EDFF),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Icon(item.$2,
                                    color: const Color(0xFF6941D9)),
                              ),
                              title: Text(item.$1,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => _openPartnerMenu(context, item.$1),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () async {
                    await AppStore.instance.logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                        context, AppRoutes.roleSelection, (_) => false);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Keluar dari akun'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPartnerMenu(BuildContext context, String menu) {
    var first = true;
    var second = menu != 'Pengaturan Akun';
    var selected = 0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(menu,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  if (menu == 'Informasi Mitra') ...[
                    const TextField(
                        decoration: InputDecoration(labelText: 'Nama Mitra')),
                    const SizedBox(height: 10),
                    const TextField(
                        decoration: InputDecoration(labelText: 'Alamat')),
                    const SizedBox(height: 10),
                    const TextField(
                        maxLines: 3,
                        decoration:
                            InputDecoration(labelText: 'Deskripsi Mitra')),
                  ] else if (menu == 'Layanan & Harga') ...[
                    SwitchListTile(
                        value: first,
                        onChanged: (value) =>
                            setSheetState(() => first = value),
                        title: const Text('Facial Basic'),
                        subtitle: const Text('Rp120.000 • 60 menit')),
                    SwitchListTile(
                        value: second,
                        onChanged: (value) =>
                            setSheetState(() => second = value),
                        title: const Text('Hair Treatment'),
                        subtitle: const Text('Rp150.000 • 90 menit')),
                    OutlinedButton.icon(
                        onPressed: () => _sheetMessage(
                            context, 'Form tambah layanan dibuka'),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah Layanan')),
                  ] else if (menu == 'Jam Operasional') ...[
                    SwitchListTile(
                        value: first,
                        onChanged: (value) =>
                            setSheetState(() => first = value),
                        title: const Text('Senin - Jumat'),
                        subtitle: const Text('08:00 - 21:00')),
                    SwitchListTile(
                        value: second,
                        onChanged: (value) =>
                            setSheetState(() => second = value),
                        title: const Text('Sabtu - Minggu'),
                        subtitle: const Text('09:00 - 20:00')),
                  ] else if (menu == 'Rekening Pencairan') ...[
                    ListTile(
                        onTap: () => setSheetState(() => selected = 0),
                        leading: Icon(selected == 0
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded),
                        title: const Text('BCA •••• 1234'),
                        subtitle: const Text('Glow Beauty Home Service')),
                    ListTile(
                        onTap: () => setSheetState(() => selected = 1),
                        leading: Icon(selected == 1
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded),
                        title: const Text('Mandiri •••• 5678'),
                        subtitle: const Text('Glow Beauty Home Service')),
                    OutlinedButton.icon(
                        onPressed: () => _sheetMessage(
                            context, 'Form tambah rekening dibuka'),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah Rekening')),
                  ] else if (menu == 'Pengaturan Akun') ...[
                    SwitchListTile(
                        value: first,
                        onChanged: (value) =>
                            setSheetState(() => first = value),
                        title: const Text('Notifikasi order baru')),
                    SwitchListTile(
                        value: second,
                        onChanged: (value) =>
                            setSheetState(() => second = value),
                        title: const Text('Notifikasi promosi')),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.lock_outline_rounded),
                        title: const Text('Ubah Password'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _sheetMessage(
                            context, 'Form ubah password dibuka')),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.dns_outlined),
                        title: const Text('Alamat API Server'),
                        subtitle: Text(AppStore.instance.apiBaseUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showApiServerDialog(context)),
                  ] else ...[
                    _helpTile(context, Icons.chat_bubble_outline_rounded,
                        'Chat Customer Service'),
                    _helpTile(context, Icons.phone_outlined,
                        'Hubungi 0812-3456-7890'),
                    _helpTile(
                        context, Icons.mail_outline_rounded, 'Email Dukungan'),
                    _helpTile(context, Icons.help_outline_rounded,
                        'Panduan Penggunaan Mitra'),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _sheetMessage(context, '$menu berhasil diperbarui');
                      },
                      child: Text(menu == 'Bantuan Mitra'
                          ? 'Tutup'
                          : 'Simpan Perubahan'),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _helpTile(BuildContext context, IconData icon, String title) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: const Color(0xFF6941D9)),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _sheetMessage(context, '$title dibuka'),
      );

  void _sheetMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showEditProfile(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            22, 0, 22, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Edit Profil Mitra',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: 'Nama Mitra')),
          const SizedBox(height: 12),
          const TextField(
              decoration: InputDecoration(labelText: 'Nomor Telepon')),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'Alamat')),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil Mitra diperbarui')));
              },
              child: const Text('Simpan Perubahan'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _RoleMetric extends StatelessWidget {
  const _RoleMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(fontSize: 10, color: _profileMuted)),
    ]);
  }
}
