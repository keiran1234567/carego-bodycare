import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/app_models.dart';
import '../utils/app_routes.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/bottom_navs.dart';
import '../widgets/info_card.dart';
import '../widgets/responsive_page.dart';

const _partnerBlue = Color(0xFF3156D3);
const _partnerPurple = Color(0xFF6941D9);
const _partnerInk = Color(0xFF151A3B);
const _partnerMuted = Color(0xFF747A96);

class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  var open = true;

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
      await AppStore.instance.refreshBookings(silent: true);
      await AppStore.instance.refreshDashboard(silent: true);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildRoleBlueTheme(
        Theme.of(context),
        primary: _partnerBlue,
        secondary: _partnerPurple,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FF),
        bottomNavigationBar: const PartnerBottomNav(currentIndex: 0),
        body: ResponsivePage(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PartnerHeader(
                  open: open,
                  onChanged: (value) => setState(() => open = value)),
              const SizedBox(height: 18),
              _RevenueHero(onReport: () => _showReport(context)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: _PartnerShortcut(
                    label: 'Kelola Layanan',
                    icon: Icons.spa_outlined,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.manageServices),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _PartnerShortcut(
                    label: 'Keuangan',
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.partnerFinance),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              const _QuickStats(),
              const SizedBox(height: 14),
              const _PartnerAnalytics(),
              const SizedBox(height: 22),
              _SectionLine(
                title: 'Perlu ditangani',
                action: 'Lihat semua',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.partnerOrders),
              ),
              const SizedBox(height: 10),
              ...AppStore.instance.bookings
                  .take(2)
                  .map((booking) => _PartnerOrderCard(
                        booking: booking,
                        handled: booking.status != 'Menunggu Mitra',
                      )),
              const SizedBox(height: 10),
              const _SectionLine(title: 'Performa minggu ini'),
              const SizedBox(height: 10),
              const _PerformanceCard(),
              const SizedBox(height: 10),
              _SectionLine(
                title: 'Tim aktif hari ini',
                action: 'Kelola',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.manageEmployees),
              ),
              const SizedBox(height: 10),
              const _TeamPreview(),
            ],
          ),
        ),
      ),
    );
  }

  void _showReport(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(22, 0, 22, 30),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Laporan Pendapatan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              SizedBox(height: 16),
              _ReportLine(label: 'Pendapatan kotor', value: 'Rp9.150.000'),
              _ReportLine(label: 'Biaya platform', value: '- Rp700.000'),
              Divider(),
              _ReportLine(
                  label: 'Pendapatan bersih',
                  value: 'Rp8.450.000',
                  strong: true),
            ]),
      ),
    );
  }
}

class _PartnerShortcut extends StatelessWidget {
  const _PartnerShortcut(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.line)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(children: [
              Icon(icon, color: _partnerPurple),
              const SizedBox(width: 9),
              Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w900))),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ]),
          ),
        ),
      );
}

class PartnerOrdersScreen extends StatefulWidget {
  const PartnerOrdersScreen({super.key});

  @override
  State<PartnerOrdersScreen> createState() => _PartnerOrdersScreenState();
}

class _PartnerOrdersScreenState extends State<PartnerOrdersScreen> {
  var selected = 0;

  @override
  void initState() {
    super.initState();
    AppStore.instance.addListener(_refresh);
    AppStore.instance.refreshBookings(silent: true).catchError((_) {});
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const filters = ['Semua', 'Masuk', 'Berjalan', 'Selesai'];
    return Theme(
      data: buildRoleBlueTheme(
        Theme.of(context),
        primary: _partnerBlue,
        secondary: _partnerPurple,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FF),
        bottomNavigationBar: const PartnerBottomNav(currentIndex: 1),
        body: ResponsivePage(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Mitra',
                            style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                color: _partnerInk)),
                        SizedBox(height: 4),
                        Text('Kelola pesanan pelanggan',
                            style: TextStyle(color: _partnerMuted)),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                      onPressed: () => _showFilter(context),
                      icon: const Icon(Icons.tune_rounded)),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => ChoiceChip(
                    label: Text(filters[index]),
                    selected: selected == index,
                    onSelected: (_) => setState(() => selected = index),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ...AppStore.instance.bookings.where((booking) {
                if (booking.status == 'Dibatalkan') return false;
                if (selected == 1) return booking.status == 'Menunggu Mitra';
                if (selected == 2) {
                  return booking.status != 'Menunggu Mitra' &&
                      booking.status != 'Selesai';
                }
                if (selected == 3) return booking.status == 'Selesai';
                return true;
              }).map((booking) => _PartnerOrderCard(
                    booking: booking,
                    compact: false,
                    handled: booking.status != 'Menunggu Mitra',
                    onHandled: () => AppStore.instance
                        .updateBookingStatus(booking.id, 'Diterima Mitra'),
                    onRejected: () => AppStore.instance
                        .updateBookingStatus(booking.id, 'Ditolak Mitra'),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilter(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Urutkan Order',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...[
                'Terbaru',
                'Jadwal terdekat',
                'Nilai terbesar'
              ].map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.sort_rounded),
                    title: Text(item),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Order diurutkan berdasarkan $item')));
                    },
                  )),
            ]),
      ),
    );
  }
}

class _PartnerHeader extends StatelessWidget {
  const _PartnerHeader({required this.open, required this.onChanged});
  final bool open;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: const Color(0xFFEDE9FF),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.spa_rounded, color: _partnerPurple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Halo, ${AppStore.instance.currentUser?.name ?? 'Mitra'}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _partnerInk)),
              const SizedBox(height: 3),
              const Text('Dashboard data langsung dari server',
                  style: TextStyle(fontSize: 12, color: _partnerMuted)),
            ],
          ),
        ),
        Column(
          children: [
            Switch(value: open, onChanged: onChanged),
            Text(open ? 'Buka' : 'Tutup',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _partnerMuted)),
          ],
        ),
      ],
    );
  }
}

class _RevenueHero extends StatelessWidget {
  const _RevenueHero({required this.onReport});
  final VoidCallback onReport;
  @override
  Widget build(BuildContext context) {
    final income = AppStore.instance.dashboard['income'] ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_partnerBlue, _partnerPurple]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x303F51C5), blurRadius: 18, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                  child: Text('Pendapatan bulan ini',
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.w700))),
              Icon(Icons.insights_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 10),
          Text(AppFormatters.currency(double.tryParse('$income')?.round() ?? 0),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  size: 18, color: Color(0xFFBDF4D4)),
              const SizedBox(width: 5),
              const Expanded(
                  child: Text('Naik 18% dari bulan lalu',
                      style: TextStyle(color: Colors.white, fontSize: 12))),
              TextButton(
                onPressed: onReport,
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact),
                child: const Text('Lihat laporan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats();
  @override
  Widget build(BuildContext context) {
    final dashboard = AppStore.instance.dashboard;
    final data = [
      (
        '${dashboard['incoming'] ?? 0}',
        'Order masuk',
        Icons.inbox_rounded,
        const Color(0xFFECE8FF),
        _partnerPurple
      ),
      (
        '${dashboard['bookings'] ?? 0}',
        'Berjalan',
        Icons.delivery_dining_rounded,
        const Color(0xFFE4F4FF),
        _partnerBlue
      ),
      (
        '${dashboard['completed'] ?? 0}',
        'Selesai',
        Icons.check_circle_rounded,
        const Color(0xFFE4F8EF),
        const Color(0xFF1B9C68)
      ),
      (
        '${AppStore.instance.mitras.isEmpty ? 0 : AppStore.instance.mitras.first.rating}',
        'Rating',
        Icons.star_rounded,
        const Color(0xFFFFF4DB),
        const Color(0xFFF3A712)
      ),
    ];
    return LayoutBuilder(builder: (context, _) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.25,
        ),
        itemBuilder: (_, index) {
          final item = data[index];
          return Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: item.$4, borderRadius: BorderRadius.circular(8)),
                    child: Icon(item.$3, size: 19, color: item.$5)),
                Text(item.$1,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _partnerInk)),
                Text(item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: _partnerMuted)),
              ],
            ),
          );
        },
      );
    });
  }
}

class _SectionLine extends StatelessWidget {
  const _SectionLine({required this.title, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _partnerInk))),
      if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
    ]);
  }
}

class _PartnerOrderCard extends StatelessWidget {
  const _PartnerOrderCard(
      {required this.booking,
      this.compact = true,
      this.handled = false,
      this.onHandled,
      this.onRejected});
  final dynamic booking;
  final bool compact;
  final bool handled;
  final VoidCallback? onHandled;
  final VoidCallback? onRejected;

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final service = _partnerServiceById(booking.serviceId);
    final selectedEmployee = _partnerEmployeeById(booking.employeeId);
    final sent = booking.status == 'Dikirim ke Pelayan' ||
        booking.status == 'Diterima Pelayan' ||
        booking.status == 'Pelayan Menuju Lokasi' ||
        booking.status == 'Sedang Dikerjakan' ||
        booking.status == 'Selesai';
    final rejected = booking.status == 'Ditolak Mitra' ||
        booking.status == 'Ditolak Pelayan' ||
        booking.status == 'Dibatalkan';
    final statusLabel = sent
        ? 'Terkirim'
        : rejected
            ? booking.status
            : handled
                ? 'Diterima'
                : 'Pesanan baru';
    return InfoCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: const Color(0xFFF1EDFF),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(service.icon, color: _partnerPurple),
          ),
          const SizedBox(width: 11),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(service.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: _partnerInk)),
                const SizedBox(height: 3),
                Text(booking.userName,
                    style: const TextStyle(fontSize: 12, color: _partnerMuted)),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(AppFormatters.currency(booking.total),
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: _partnerPurple)),
            const SizedBox(height: 4),
            _StatusPill(label: statusLabel, sent: sent, rejected: rejected),
          ]),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: const Color(0xFFF5F2FF),
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: Colors.white,
              child: Text(selectedEmployee.name.characters.first,
                  style: const TextStyle(
                      color: _partnerPurple, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pelayan pilihan User',
                      style: TextStyle(fontSize: 9, color: _partnerMuted)),
                  const SizedBox(height: 2),
                  Text(selectedEmployee.name,
                      style: const TextStyle(
                          fontSize: 12,
                          color: _partnerInk,
                          fontWeight: FontWeight.w900)),
                  Text(selectedEmployee.specialty,
                      style:
                          const TextStyle(fontSize: 9, color: _partnerMuted)),
                ],
              ),
            ),
            const Icon(Icons.verified_rounded, size: 18, color: _partnerPurple),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.schedule_rounded, size: 17, color: _partnerMuted),
          const SizedBox(width: 6),
          Expanded(
              child: Text(booking.schedule,
                  style: const TextStyle(fontSize: 12, color: _partnerMuted))),
        ]),
        if (!compact) ...[
          const SizedBox(height: 7),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.location_on_outlined,
                size: 17, color: _partnerMuted),
            const SizedBox(width: 6),
            Expanded(
                child: Text(booking.address,
                    style:
                        const TextStyle(fontSize: 12, color: _partnerMuted))),
          ]),
        ],
        const SizedBox(height: 12),
        if (!handled)
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: onRejected ??
                        () => AppStore.instance
                            .updateBookingStatus(booking.id, 'Ditolak Mitra'),
                    child: const Text('Tolak'))),
            const SizedBox(width: 8),
            Expanded(
                child: FilledButton(
                    onPressed: onHandled ??
                        () => Navigator.pushNamed(
                            context, AppRoutes.partnerOrders),
                    child: const Text('Terima'))),
          ])
        else
          SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                  onPressed: sent || rejected
                      ? null
                      : () =>
                          _confirmSelectedEmployee(context, selectedEmployee),
                  icon: Icon(
                      sent ? Icons.check_circle_rounded : Icons.send_rounded),
                  label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(sent
                          ? 'Terkirim'
                          : rejected
                              ? booking.status
                              : 'Kirim ke ${selectedEmployee.name.split(' ').first}')))),
      ]),
    );
  }

  void _confirmSelectedEmployee(BuildContext context, dynamic employee) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Konfirmasi Pelayan Pilihan User',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...[employee].map((employee) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                        child: Text(employee.name.substring(0, 1))),
                    title: Text(employee.name),
                    subtitle: Text(
                        '${employee.specialty} • Rating ${employee.rating}'),
                    trailing: const Icon(Icons.send_rounded),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await AppStore.instance.updateBookingStatus(
                            booking.id, 'Dikirim ke Pelayan');
                        if (context.mounted) {
                          _message(
                              context, 'Order terkirim ke ${employee.name}');
                        }
                      } catch (error) {
                        if (context.mounted) _message(context, '$error');
                      }
                    },
                  )),
            ]),
      ),
    );
  }
}

class _ReportLine extends StatelessWidget {
  const _ReportLine(
      {required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: strong ? FontWeight.w900 : FontWeight.w500))),
          Text(value,
              style: TextStyle(
                  fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
                  color: strong ? _partnerPurple : _partnerInk)),
        ]),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(
      {required this.label, this.sent = false, this.rejected = false});
  final String label;
  final bool sent;
  final bool rejected;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: rejected
                ? const Color(0xFFFFE8EC)
                : sent
                    ? const Color(0xFFE8ECFF)
                    : const Color(0xFFE8F7F0),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                fontSize: 9,
                color: rejected
                    ? const Color(0xFFD33C52)
                    : sent
                        ? _partnerBlue
                        : const Color(0xFF188A5B),
                fontWeight: FontWeight.w800)),
      );
}

class _PartnerAnalytics extends StatelessWidget {
  const _PartnerAnalytics();

  @override
  Widget build(BuildContext context) {
    final dashboard = AppStore.instance.dashboard;
    return Column(children: [
      _AnalyticsCard(
          title: 'Booking Harian',
          items: (dashboard['daily_bookings'] as List?) ?? const [],
          labelKey: 'date'),
      const SizedBox(height: 10),
      _AnalyticsCard(
          title: 'Booking Bulanan',
          items: (dashboard['monthly_bookings'] as List?) ?? const [],
          labelKey: 'month'),
      const SizedBox(height: 10),
      _AnalyticsCard(
          title: 'Pendapatan',
          items: (dashboard['monthly_income'] as List?) ?? const [],
          labelKey: 'month'),
      const SizedBox(height: 10),
      _AnalyticsCard(
          title: 'Layanan Terlaris',
          items: (dashboard['top_services'] as List?) ?? const [],
          labelKey: 'service'),
    ]);
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard(
      {required this.title, required this.items, required this.labelKey});
  final String title;
  final List items;
  final String labelKey;

  @override
  Widget build(BuildContext context) {
    final values = items.map((raw) {
      final item = Map<String, dynamic>.from(raw as Map);
      return double.tryParse('${item['total'] ?? 0}') ?? 0;
    }).toList();
    final max =
        values.fold<double>(1, (value, item) => item > value ? item : value);
    return InfoCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: _partnerInk)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Text('Belum ada data.', style: TextStyle(color: _partnerMuted))
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(items.length, (index) {
              final item = Map<String, dynamic>.from(items[index] as Map);
              final layanan = item['layanan'] as Map?;
              final label = layanan?['name'] ?? item[labelKey] ?? '-';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${values[index].round()}',
                            style: const TextStyle(
                                fontSize: 8, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Container(
                          height: 18 + (values[index] / max * 72),
                          decoration: BoxDecoration(
                            color: _partnerPurple,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('$label',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 8, color: _partnerMuted)),
                      ]),
                ),
              );
            }),
          ),
      ]),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard();
  @override
  Widget build(BuildContext context) => InfoCard(
        child: Column(children: [
          const Row(children: [
            Expanded(
                child: Text('Target penyelesaian order',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: _partnerInk))),
            Text('82%',
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: _partnerPurple)),
          ]),
          const SizedBox(height: 10),
          const LinearProgressIndicator(
              value: .82,
              minHeight: 8,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: _partnerPurple,
              backgroundColor: Color(0xFFECEAF4)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _miniMetric('24', 'Order minggu ini')),
            Expanded(child: _miniMetric('38 menit', 'Respons rata-rata')),
            Expanded(child: _miniMetric('98%', 'Kepuasan')),
          ]),
        ]),
      );

  Widget _miniMetric(String value, String label) => Column(children: [
        Text(value,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: _partnerInk)),
        const SizedBox(height: 3),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: _partnerMuted)),
      ]);
}

class _TeamPreview extends StatelessWidget {
  const _TeamPreview();
  @override
  Widget build(BuildContext context) {
    final mitraId = AppStore.instance.currentMitra?.id;
    final employees = AppStore.instance.pelayans
        .where((employee) => employee.mitraId == mitraId)
        .toList();
    return InfoCard(
      child: Row(
        children: employees
            .take(3)
            .map((employee) => Expanded(
                  child: Column(children: [
                    CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFEDE9FF),
                        child: Text(employee.name.characters.first,
                            style: const TextStyle(
                                color: _partnerPurple,
                                fontWeight: FontWeight.w900))),
                    const SizedBox(height: 6),
                    Text(employee.name.split(' ').first,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800)),
                    Text(employee.available ? 'Tersedia' : 'Bertugas',
                        style: TextStyle(
                            fontSize: 9,
                            color: employee.available
                                ? const Color(0xFF188A5B)
                                : _partnerMuted)),
                  ]),
                ))
            .toList(),
      ),
    );
  }
}

Layanan _partnerServiceById(String id) {
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

Pelayan _partnerEmployeeById(String id) {
  final employees = AppStore.instance.pelayans;
  final index = employees.indexWhere((employee) => employee.id == id);
  return index >= 0
      ? employees[index]
      : const Pelayan(
          id: '',
          mitraId: '',
          name: 'Pelayan',
          email: '',
          phone: '',
          specialty: '',
          rating: 0,
          available: false,
          photoUrl: '',
          portfolioItems: [],
        );
}
