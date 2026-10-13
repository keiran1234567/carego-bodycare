import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/app_store.dart';
import '../models/app_models.dart';
import '../utils/app_routes.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/info_card.dart';
import '../widgets/responsive_page.dart';

const _employeePurple = Color(0xFF6541D8);
const _employeeBlue = Color(0xFF3159D8);
const _employeeInk = Color(0xFF151A3B);
const _employeeMuted = Color(0xFF747A96);

String _employeeDisplayStatus(String status) {
  return switch (status) {
    'Dikirim ke Pelayan' => 'Tugas Baru',
    'Diterima Pelayan' => 'Diterima',
    'Pelayan Menuju Lokasi' => 'Menuju Lokasi',
    _ => status,
  };
}

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  var currentIndex = 0;
  bool? availabilityOverride;
  final statuses = <String, String>{};

  @override
  void initState() {
    super.initState();
    AppStore.instance.addListener(_refresh);
    _sync();
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _sync() async {
    try {
      await AppStore.instance.refreshCatalog(silent: true);
      await AppStore.instance.refreshBookings(silent: true);
      await AppStore.instance.refreshDashboard(silent: true);
      await AppStore.instance.refreshIncome(silent: true);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _updateStatus(String id, String status) async {
    setState(() => statuses[id] = status);
    try {
      await AppStore.instance.updateBookingStatus(id, status);
      await AppStore.instance.refreshDashboard(silent: true);
      statuses.remove(id);
      if (mounted) setState(() {});
    } catch (error) {
      if (!mounted) return;
      statuses.remove(id);
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = availabilityOverride ??
        AppStore.instance.currentPelayan?.available ??
        true;
    return Theme(
      data: buildRoleBlueTheme(
        Theme.of(context),
        primary: _employeeBlue,
        secondary: _employeePurple,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FF),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: AppColors.softBlue,
            surfaceTintColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                color: states.contains(WidgetState.selected)
                    ? _employeeBlue
                    : _employeeMuted,
                fontSize: 12,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? _employeeBlue
                    : _employeeMuted,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) =>
                setState(() => currentIndex = index),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_rounded), label: 'Beranda'),
              NavigationDestination(
                  icon: Icon(Icons.assignment_rounded), label: 'Tugas'),
              NavigationDestination(
                  icon: Icon(Icons.history_rounded), label: 'Riwayat'),
              NavigationDestination(
                  icon: Icon(Icons.person_rounded), label: 'Profil'),
            ],
          ),
        ),
        body: IndexedStack(
          index: currentIndex,
          children: [
            _EmployeeHome(
              available: available,
              onAvailabilityChanged: (value) async {
                final pelayan = AppStore.instance.currentPelayan;
                if (pelayan == null) return;
                setState(() => availabilityOverride = value);
                try {
                  await AppStore.instance
                      .updatePelayanAvailability(pelayan.id, value);
                } catch (_) {
                  if (mounted) setState(() => availabilityOverride = null);
                }
              },
              statuses: statuses,
              onStatusChanged: _updateStatus,
              openTasks: () => setState(() => currentIndex = 1),
            ),
            _EmployeeTasks(
              statuses: statuses,
              onStatusChanged: _updateStatus,
            ),
            const _EmployeeHistory(),
            const _EmployeeProfile(),
          ],
        ),
      ),
    );
  }
}

class _EmployeeHome extends StatelessWidget {
  const _EmployeeHome({
    required this.available,
    required this.onAvailabilityChanged,
    required this.statuses,
    required this.onStatusChanged,
    required this.openTasks,
  });

  final bool available;
  final ValueChanged<bool> onAvailabilityChanged;
  final Map<String, String> statuses;
  final void Function(String, String) onStatusChanged;
  final VoidCallback openTasks;

  @override
  Widget build(BuildContext context) {
    final tasks = _sortedEmployeeBookings(AppStore.instance.bookings);
    final nextTask = tasks.isEmpty ? null : tasks.first;
    return ResponsivePage(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _EmployeeHeader(available: available, onChanged: onAvailabilityChanged),
        const SizedBox(height: 18),
        const _ActivePartnerCard(),
        const SizedBox(height: 14),
        const _EmployeeStats(),
        const SizedBox(height: 10),
        const _EmployeeIncomeStats(),
        const SizedBox(height: 22),
        _SectionLine(
            title: 'Tugas berikutnya', action: 'Lihat semua', onTap: openTasks),
        const SizedBox(height: 10),
        if (nextTask == null)
          const InfoCard(child: Text('Belum ada tugas dari server.'))
        else
          _TaskCard(
            booking: nextTask,
            status: statuses[nextTask.id] ??
                _employeeDisplayStatus(nextTask.status),
            onStatusChanged: (value) => onStatusChanged(nextTask.id, value),
          ),
        const SizedBox(height: 10),
        const _SectionLine(title: 'Jadwal hari ini'),
        const SizedBox(height: 10),
        _TodaySchedule(bookings: AppStore.instance.bookings),
        const SizedBox(height: 10),
        const _SectionLine(title: 'Pencapaian Anda'),
        const SizedBox(height: 10),
        const _AchievementCard(),
      ]),
    );
  }
}

class _EmployeeTasks extends StatelessWidget {
  const _EmployeeTasks({required this.statuses, required this.onStatusChanged});
  final Map<String, String> statuses;
  final void Function(String, String) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tugas Saya',
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: _employeeInk)),
        const SizedBox(height: 4),
        Text('Kelola tugas dari ${_currentPartnerName()}',
            style: const TextStyle(color: _employeeMuted)),
        const SizedBox(height: 18),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              ChoiceChip(label: Text('Hari ini'), selected: true),
              SizedBox(width: 8),
              ChoiceChip(label: Text('Mendatang'), selected: false),
              SizedBox(width: 8),
              ChoiceChip(label: Text('Selesai'), selected: false),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (AppStore.instance.bookings.isEmpty)
          const InfoCard(child: Text('Belum ada tugas yang dikirim Mitra.'))
        else
          ..._sortedEmployeeBookings(AppStore.instance.bookings)
              .map((booking) => _TaskCard(
                    booking: booking,
                    status: statuses[booking.id] ??
                        _employeeDisplayStatus(booking.status),
                    onStatusChanged: (value) =>
                        onStatusChanged(booking.id, value),
                  )),
      ]),
    );
  }
}

class _EmployeeHistory extends StatelessWidget {
  const _EmployeeHistory();
  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Riwayat Pekerjaan',
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: _employeeInk)),
        const SizedBox(height: 4),
        const Text('Pekerjaan yang sudah Anda selesaikan',
            style: TextStyle(color: _employeeMuted)),
        const SizedBox(height: 18),
        const _HistorySummary(),
        const SizedBox(height: 16),
        ...AppStore.instance.bookings
            .where((booking) => booking.status == 'Selesai')
            .take(3)
            .map((booking) {
          final service = _serviceById(booking.serviceId);
          return InfoCard(
            child: Row(children: [
              Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: const Color(0xFFECE8FF),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(service.icon, color: _employeePurple)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(service.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, color: _employeeInk)),
                    const SizedBox(height: 4),
                    Text(booking.userName,
                        style: const TextStyle(
                            fontSize: 12, color: _employeeMuted)),
                    Text(booking.schedule,
                        style: const TextStyle(
                            fontSize: 11, color: _employeeMuted)),
                  ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Selesai',
                    style: TextStyle(
                        color: Color(0xFF188A5B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(AppFormatters.currency(booking.total),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800)),
              ]),
            ]),
          );
        }),
      ]),
    );
  }
}

class _EmployeeProfile extends StatelessWidget {
  const _EmployeeProfile();
  @override
  Widget build(BuildContext context) {
    final pelayan = AppStore.instance.currentPelayan;
    const menus = [
      ('Data Pribadi', Icons.person_outline_rounded),
      ('Mitra Tempat Bekerja', Icons.storefront_outlined),
      ('Keahlian & Sertifikat', Icons.workspace_premium_outlined),
      ('Portofolio', Icons.photo_library_outlined),
      ('Pengaturan', Icons.settings_outlined),
    ];
    return ResponsivePage(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      child: Column(children: [
        const Align(
            alignment: Alignment.centerLeft,
            child: Text('Profil Pelayan',
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: _employeeInk))),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_employeeBlue, _employeePurple]),
              borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                backgroundImage: pelayan?.photoUrl.isNotEmpty == true
                    ? NetworkImage(pelayan!.photoUrl)
                    : null,
                child: pelayan?.photoUrl.isNotEmpty == true
                    ? null
                    : const Icon(Icons.person_rounded,
                        size: 48, color: _employeePurple)),
            const SizedBox(height: 12),
            Text(
                pelayan?.name ??
                    AppStore.instance.currentUser?.name ??
                    'Pelayan',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
                '${pelayan?.specialty.isNotEmpty == true ? pelayan!.specialty : 'Pelayan'} • Rating ${(pelayan?.rating ?? 0).toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white70)),
            // ignore: prefer_const_constructors
            Text('Terapis Kecantikan • Rating 4.9',
                style: const TextStyle(
                    fontSize: 0, height: 0, color: Colors.transparent)),
          ]),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _pickProfilePhoto(context),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Upload / Edit Foto Profil'),
          ),
        ),
        const SizedBox(height: 16),
        InfoCard(
          child: Column(
              children: menus
                  .map((item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF1EDFF),
                                borderRadius: BorderRadius.circular(8)),
                            child: Icon(item.$2, color: _employeePurple)),
                        title: Text(item.$1,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _openEmployeeMenu(context, item.$1),
                      ))
                  .toList()),
        ),
        SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await AppStore.instance.logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.roleSelection, (_) => false);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar dari akun'),
            )),
      ]),
    );
  }

  void _openEmployeeMenu(BuildContext context, String menu) {
    var first = true;
    var second = false;
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
                  if (menu == 'Data Pribadi') ...[
                    const TextField(
                        decoration: InputDecoration(labelText: 'Nama Lengkap')),
                    const SizedBox(height: 10),
                    const TextField(
                        decoration:
                            InputDecoration(labelText: 'Nomor Telepon')),
                    const SizedBox(height: 10),
                    const TextField(
                        decoration: InputDecoration(labelText: 'Email')),
                  ] else if (menu == 'Mitra Tempat Bekerja') ...[
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          CircleAvatar(child: Icon(Icons.storefront_rounded)),
                      title: Text('Glow Beauty Home Service',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      subtitle:
                          Text('Mitra aktif • Jakarta Selatan • Rating 4.8'),
                      trailing:
                          Icon(Icons.verified_rounded, color: _employeePurple),
                    ),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton.icon(
                              onPressed: () => _employeeMessage(
                                  context, 'Chat Mitra dibuka'),
                              icon:
                                  const Icon(Icons.chat_bubble_outline_rounded),
                              label: const Text('Chat'))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: FilledButton.icon(
                              onPressed: () => _employeeMessage(
                                  context, 'Nomor Mitra dihubungi'),
                              icon: const Icon(Icons.phone_outlined),
                              label: const Text('Hubungi'))),
                    ]),
                  ] else if (menu == 'Keahlian & Sertifikat') ...[
                    SwitchListTile(
                        value: first,
                        onChanged: (value) =>
                            setSheetState(() => first = value),
                        title: const Text('Facial & Perawatan Wajah'),
                        subtitle: const Text('Keahlian utama')),
                    SwitchListTile(
                        value: second,
                        onChanged: (value) =>
                            setSheetState(() => second = value),
                        title: const Text('Make Up'),
                        subtitle: const Text('Keahlian tambahan')),
                    OutlinedButton.icon(
                        onPressed: () => _employeeMessage(
                            context, 'Pemilih dokumen sertifikat dibuka'),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Tambah Sertifikat')),
                  ] else if (menu == 'Portofolio') ...[
                    if (AppStore
                            .instance.currentPelayan?.portfolioItems.isEmpty ??
                        true)
                      const Text('Belum ada portofolio.')
                    else
                      ...AppStore.instance.currentPelayan!.portfolioItems.map(
                        (item) => ListTile(
                          leading: const Icon(Icons.image_outlined),
                          title: Text(item.title),
                          subtitle: Text(item.description),
                          trailing: IconButton(
                            onPressed: () async {
                              await AppStore.instance.deletePortfolio(item.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                          onPressed: () => _pickPortfolio(context),
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Tambah Portofolio')),
                    ),
                  ] else ...[
                    SwitchListTile(
                        value: first,
                        onChanged: (value) =>
                            setSheetState(() => first = value),
                        title: const Text('Notifikasi tugas baru')),
                    SwitchListTile(
                        value: second,
                        onChanged: (value) =>
                            setSheetState(() => second = value),
                        title: const Text('Bagikan status online otomatis')),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.lock_outline_rounded),
                        title: const Text('Ubah Password'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _employeeMessage(
                            context, 'Form ubah password dibuka')),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _employeeMessage(context, '$menu berhasil diperbarui');
                      },
                      child: const Text('Simpan Perubahan'),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  void _employeeMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickProfilePhoto(BuildContext context) async {
    final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 72, maxWidth: 1200);
    if (file == null) return;
    try {
      await AppStore.instance
          .uploadProfilePhoto(base64Encode(await file.readAsBytes()));
      if (context.mounted) {
        _employeeMessage(context, 'Foto profil berhasil diperbarui.');
      }
    } catch (error) {
      if (context.mounted) _employeeMessage(context, '$error');
    }
  }

  Future<void> _pickPortfolio(BuildContext context) async {
    final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 72, maxWidth: 1600);
    if (file == null) return;
    try {
      await AppStore.instance.uploadPortfolio(
          title: 'Hasil Kerja ${DateTime.now().day}/${DateTime.now().month}',
          base64Image: base64Encode(await file.readAsBytes()));
      if (context.mounted) {
        Navigator.pop(context);
        _employeeMessage(context, 'Portofolio berhasil ditambahkan.');
      }
    } catch (error) {
      if (context.mounted) _employeeMessage(context, '$error');
    }
  }
}

class _EmployeeHeader extends StatelessWidget {
  const _EmployeeHeader({required this.available, required this.onChanged});
  final bool available;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final user = AppStore.instance.currentUser;
    return Row(children: [
      CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFECE8FF),
          backgroundImage: user?.photoUrl.isNotEmpty == true
              ? NetworkImage(user!.photoUrl)
              : null,
          child: user?.photoUrl.isNotEmpty == true
              ? null
              : const Icon(Icons.person_rounded,
                  color: _employeePurple, size: 30)),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Halo, ${user?.name ?? 'Pelayan'}',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _employeeInk)),
        const SizedBox(height: 3),
        const Text('Siap melayani hari ini?',
            style: TextStyle(fontSize: 12, color: _employeeMuted)),
      ])),
      Column(children: [
        Switch(value: available, onChanged: onChanged),
        Text(available ? 'Online' : 'Offline',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: available ? const Color(0xFF188A5B) : _employeeMuted)),
      ]),
      IconButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.userNotifications),
          icon: const Icon(Icons.notifications_none_rounded)),
    ]);
  }
}

class _ActivePartnerCard extends StatelessWidget {
  const _ActivePartnerCard();
  @override
  Widget build(BuildContext context) {
    final partner = AppStore.instance.currentPelayan?.mitraId;
    final matches =
        AppStore.instance.mitras.where((item) => item.id == partner).toList();
    final name = matches.isEmpty ? 'Mitra belum tersedia' : matches.first.name;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFE8F2FF), Color(0xFFF2EDFF)]),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.storefront_rounded, color: _employeePurple)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mitra Aktif',
              style: TextStyle(fontSize: 10, color: _employeeMuted)),
          const SizedBox(height: 3),
          Text(name,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: _employeeInk)),
        ])),
        const Icon(Icons.verified_rounded, color: _employeePurple),
      ]),
    );
  }
}

class _EmployeeStats extends StatelessWidget {
  const _EmployeeStats();
  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final now = DateTime.now();
    final today = store.bookings.where((item) {
      final value = _bookingDateTime(item);
      return value.year == now.year &&
          value.month == now.month &&
          value.day == now.day;
    }).length;
    final completed =
        store.bookings.where((item) => item.status == 'Selesai').length;
    final rating = store.currentPelayan?.rating.toStringAsFixed(1) ?? '0.0';
    return Row(children: [
      Expanded(
          child: _stat('$today', 'Tugas hari ini', Icons.assignment_rounded,
              const Color(0xFFECE8FF))),
      const SizedBox(width: 8),
      Expanded(
          child: _stat(
              rating, 'Rating', Icons.star_rounded, const Color(0xFFFFF4DB))),
      const SizedBox(width: 8),
      Expanded(
          child: _stat('$completed', 'Selesai', Icons.check_circle_rounded,
              const Color(0xFFE4F8EF))),
    ]);
  }

  Widget _stat(String value, String label, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line)),
        child: Column(children: [
          Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: _employeePurple)),
          const SizedBox(height: 7),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _employeeInk)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: _employeeMuted)),
        ]),
      );
}

class _EmployeeIncomeStats extends StatelessWidget {
  const _EmployeeIncomeStats();

  @override
  Widget build(BuildContext context) {
    final data = AppStore.instance.dashboard;
    final items = [
      ('Hari Ini', data['income_today'] ?? 0),
      ('Mingguan', data['income_week'] ?? 0),
      ('Bulanan', data['income_month'] ?? 0),
    ];
    return Row(
      children: items.map((item) {
        final value = double.tryParse('${item.$2}')?.round() ?? 0;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: item == items.last ? 0 : 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(children: [
              Text(AppFormatters.currency(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _employeePurple)),
              const SizedBox(height: 4),
              Text(item.$1,
                  style: const TextStyle(fontSize: 9, color: _employeeMuted)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionLine extends StatelessWidget {
  const _SectionLine({required this.title, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _employeeInk))),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ]);
}

class _TaskCard extends StatelessWidget {
  const _TaskCard(
      {required this.booking,
      required this.status,
      required this.onStatusChanged});
  final dynamic booking;
  final String status;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final service = _serviceById(booking.serviceId);
    final statusColor = switch (status) {
      'Tugas Baru' => const Color(0xFFF2A900),
      'Diterima' => const Color(0xFF3159D8),
      'Menuju Lokasi' => const Color(0xFF6C48D9),
      'Sedang Dikerjakan' => const Color(0xFF188A5B),
      'Selesai' => const Color(0xFF188A5B),
      _ => _employeeMuted,
    };
    final next = switch (status) {
      'Tugas Baru' => 'Terima Tugas',
      'Diterima' => 'Menuju Lokasi',
      'Menuju Lokasi' => 'Sedang Dikerjakan',
      'Sedang Dikerjakan' => 'Selesai',
      _ => 'Selesai',
    };
    return InfoCard(
      padding: const EdgeInsets.all(15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: const Color(0xFFF1EDFF),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(service.icon, color: _employeePurple)),
          const SizedBox(width: 11),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(service.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: _employeeInk)),
                const SizedBox(height: 3),
                Text(booking.userName,
                    style:
                        const TextStyle(fontSize: 12, color: _employeeMuted)),
              ])),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(status,
                  style: TextStyle(
                      fontSize: 9,
                      color: statusColor,
                      fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 12),
        _detail(Icons.schedule_rounded, booking.schedule),
        _detail(Icons.location_on_outlined, booking.address),
        _detail(Icons.notes_outlined, booking.note),
        const SizedBox(height: 10),
        Row(children: [
          if (status == 'Tugas Baru') ...[
            Expanded(
                child: OutlinedButton(
                    onPressed: () => onStatusChanged('Ditolak Pelayan'),
                    child: const Text('Tolak'))),
            const SizedBox(width: 8),
          ],
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.chat,
                        arguments: booking.id,
                      ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Chat'))),
          const SizedBox(width: 8),
          Expanded(
              child: FilledButton(
                  onPressed: status == 'Selesai' || status == 'Ditolak Pelayan'
                      ? null
                      : () => onStatusChanged(
                          next == 'Terima Tugas' ? 'Diterima' : next),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(next)))),
        ]),
      ]),
    );
  }

  Widget _detail(IconData icon, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 17, color: _employeePurple),
          const SizedBox(width: 7),
          Expanded(
              child: Text(value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: _employeeMuted))),
        ]),
      );
}

String _currentPartnerName() {
  final store = AppStore.instance;
  final mitraId = store.currentPelayan?.mitraId;
  final matches = store.mitras.where((item) => item.id == mitraId);
  return matches.isEmpty ? 'Mitra Anda' : matches.first.name;
}

class _TodaySchedule extends StatelessWidget {
  const _TodaySchedule({required this.bookings});
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedEmployeeBookings(bookings);
    return InfoCard(
      child: sorted.isEmpty
          ? const Text('Belum ada order yang dikirim Mitra.',
              style: TextStyle(color: _employeeMuted))
          : Column(
              children: List.generate(sorted.length, (index) {
                final booking = sorted[index];
                final service = _serviceById(booking.serviceId);
                final status = _employeeDisplayStatus(booking.status);
                final color = booking.status == 'Selesai'
                    ? const Color(0xFF188A5B)
                    : booking.status == 'Dikirim ke Pelayan'
                        ? const Color(0xFFF2A900)
                        : _employeePurple;
                return Column(children: [
                  if (index > 0) const Divider(),
                  _row(booking.time, service.name, status, color),
                ]);
              }),
            ),
    );
  }

  Widget _row(String time, String service, String status, Color color) =>
      Row(children: [
        SizedBox(
            width: 48,
            child: Text(time,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: _employeeInk))),
        Expanded(child: Text(service, style: const TextStyle(fontSize: 12))),
        Text(status,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w800)),
      ]);
}

DateTime _bookingDateTime(Booking booking) {
  final date = booking.date.split('/');
  final time = booking.time.split(':');
  if (date.length != 3 || time.length != 2) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime(
    int.tryParse(date[2]) ?? 1970,
    int.tryParse(date[1]) ?? 1,
    int.tryParse(date[0]) ?? 1,
    int.tryParse(time[0]) ?? 0,
    int.tryParse(time[1]) ?? 0,
  );
}

List<Booking> _sortedEmployeeBookings(List<Booking> bookings) {
  final sorted = [...bookings];
  sorted.sort((a, b) {
    final priority =
        _statusPriority(a.status).compareTo(_statusPriority(b.status));
    if (priority != 0) return priority;
    return _bookingDateTime(a).compareTo(_bookingDateTime(b));
  });
  return sorted;
}

int _statusPriority(String status) {
  return switch (status) {
    'Dikirim ke Pelayan' => 0,
    'Diterima Pelayan' => 1,
    'Pelayan Menuju Lokasi' => 2,
    'Menuju Lokasi' => 2,
    'Sedang Dikerjakan' => 3,
    'Selesai' => 4,
    'Ditolak Pelayan' => 5,
    _ => 6,
  };
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF5DD),
            borderRadius: BorderRadius.circular(14)),
        child: const Row(children: [
          CircleAvatar(
              backgroundColor: Colors.white,
              child:
                  Icon(Icons.emoji_events_rounded, color: Color(0xFFF2A900))),
          SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Terapis Favorit Minggu Ini',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, color: _employeeInk)),
                SizedBox(height: 4),
                Text('Pertahankan rating dan pelayanan terbaik Anda.',
                    style: TextStyle(fontSize: 11, color: _employeeMuted)),
              ])),
        ]),
      );
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary();
  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final completed =
        store.bookings.where((booking) => booking.status == 'Selesai').length;
    final rating = store.currentPelayan?.rating.toStringAsFixed(1) ?? '0.0';
    final income =
        double.tryParse('${store.income['total'] ?? 0}')?.round() ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient:
              const LinearGradient(colors: [_employeeBlue, _employeePurple]),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Expanded(
            child: Column(children: [
          Text('$completed',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const Text('Total tugas',
              style: TextStyle(color: Colors.white70, fontSize: 10))
        ])),
        Expanded(
            child: Column(children: [
          Text(rating,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const Text('Rating',
              style: TextStyle(color: Colors.white70, fontSize: 10))
        ])),
        Expanded(
            child: Column(children: [
          Text(AppFormatters.currency(income),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
          const Text('Pendapatan',
              style: TextStyle(color: Colors.white70, fontSize: 10))
        ])),
      ]),
    );
  }
}

Layanan _serviceById(String id) {
  final services = AppStore.instance.layanans;
  final index = services.indexWhere((service) => service.id == id);
  return index >= 0
      ? services[index]
      : const Layanan(
          id: '',
          name: 'Layanan',
          category: '',
          duration: '',
          price: 0,
          icon: Icons.spa_outlined,
          description: '',
          active: true,
        );
}
