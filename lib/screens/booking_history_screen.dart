import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../data/dummy_data.dart';
import '../models/app_models.dart';
import '../utils/app_routes.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/bottom_navs.dart';

const _historyBlue = Color(0xFF3454D1);
const _historyLine = Color(0xFFE7E9F0);
const _historyMuted = Color(0xFF747985);

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  var filter = 0;

  @override
  void initState() {
    super.initState();
    AppStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildRoleBlueTheme(
        Theme.of(context),
        primary: _historyBlue,
        secondary: const Color(0xFF4D77F6),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFCFE),
        bottomNavigationBar: const UserBottomNav(currentIndex: 1),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                children: [
                  const _HistoryHeader(),
                  const SizedBox(height: 20),
                  _HistoryFilters(
                      selected: filter,
                      onChanged: (value) => setState(() => filter = value)),
                  const SizedBox(height: 14),
                  if (AppStore.instance.bookings.isNotEmpty) ...[
                    _LiveBookingStatus(
                        booking: AppStore.instance.bookings.first),
                    const SizedBox(height: 22),
                  ],
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Riwayat Booking',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w900)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('Terbaru'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(92, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          side: const BorderSide(color: _historyLine),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                          textStyle: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (AppStore.instance.bookings.isEmpty)
                    const Center(child: Text('Belum ada booking dari server.'))
                  else
                    ...List.generate(AppStore.instance.bookings.length,
                        (index) => _HistoryCard(index: index)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveBookingStatus extends StatelessWidget {
  const _LiveBookingStatus({required this.booking});
  final dynamic booking;

  @override
  Widget build(BuildContext context) {
    final service = serviceById(booking.serviceId);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE1FF)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Icon(service.icon, color: _historyBlue),
        ),
        const SizedBox(width: 11),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Status booking terbaru',
                style: TextStyle(fontSize: 9, color: _historyMuted)),
            const SizedBox(height: 3),
            Text(service.name,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            Text(booking.status,
                style: const TextStyle(
                    fontSize: 11,
                    color: _historyBlue,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.userTracking,
              arguments: booking.id),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ]),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Riwayat',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              SizedBox(height: 4),
              Text('Lihat riwayat booking dan layanan Anda',
                  style: TextStyle(fontSize: 12, color: _historyMuted)),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.userNotifications),
              icon: const Icon(Icons.notifications_none_rounded, size: 27),
            ),
            Positioned(
              right: 1,
              top: 0,
              child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle)),
            ),
          ],
        ),
        const SizedBox(width: 14),
        const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFFE8EEFF),
          child: Icon(Icons.person_rounded, color: _historyBlue),
        ),
      ],
    );
  }
}

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Semua', 'Menunggu', 'Selesai', 'Dibatalkan'];
    const icons = [
      Icons.grid_view_rounded,
      Icons.schedule_rounded,
      Icons.check_circle_outline_rounded,
      Icons.cancel_outlined
    ];
    const colors = [
      _historyBlue,
      Color(0xFF575B64),
      Color(0xFF25A777),
      Color(0xFFE35865)
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _historyLine),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = selected == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
                decoration: BoxDecoration(
                    color:
                        active ? const Color(0xFFF2F3FF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icons[index], size: 16, color: colors[index]),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        labels[index],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10,
                            color:
                                active ? _historyBlue : const Color(0xFF30343D),
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final booking = AppStore.instance.bookings[index];
    final service = serviceById(booking.serviceId);
    final partner = partnerById(booking.partnerId);
    final histories = historiesByBookingId(booking.id);
    final status = _displayBookingStatus(booking.status);
    final statusColor = _historyStatusColor(status);
    final footerColor = _historyFooterColor(status);
    final footerText = _historyFooterText(status, histories);
    final footerAction = _historyFooterAction(status, histories);
    final address = booking.address.trim().isEmpty
        ? 'Alamat belum tersedia'
        : booking.address.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _historyLine)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    index.isEven
                        ? 'assets/images/home_hero.png'
                        : 'assets/images/salon_interior.png',
                    width: 116,
                    height: 104,
                    fit: BoxFit.cover,
                    alignment:
                        index.isEven ? Alignment.centerRight : Alignment.center,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(partner.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: _historyMuted)),
                      const SizedBox(height: 9),
                      _DetailLine(
                          icon: Icons.calendar_month_outlined,
                          text: booking.date),
                      _DetailLine(
                          icon: Icons.schedule_rounded, text: booking.time),
                      _DetailLine(
                          icon: Icons.location_on_outlined, text: address),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(status,
                            style: TextStyle(fontSize: 9, color: statusColor)),
                      ),
                      const SizedBox(height: 8),
                      Text(AppFormatters.currency(booking.total),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 30,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.userTracking,
                              arguments: booking.id),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            side: const BorderSide(color: Color(0xFF9DA8DA)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7)),
                          ),
                          child: const Text('Lihat Detail',
                              style:
                                  TextStyle(fontSize: 9, color: _historyBlue)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: footerColor,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    footerText,
                    style: TextStyle(fontSize: 9, color: statusColor),
                  ),
                ),
                if (status == 'Selesai')
                  ...List.generate(
                      5,
                      (_) => const Icon(Icons.star_rounded,
                          color: Color(0xFFFFC93C), size: 15))
                else if (footerAction != null)
                  Text('$footerAction  >',
                      style: const TextStyle(fontSize: 9, color: _historyBlue)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _historyMuted),
          const SizedBox(width: 5),
          Expanded(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8.5, color: _historyMuted))),
        ],
      ),
    );
  }
}

String _displayBookingStatus(String status) {
  final normalized = status.trim().toUpperCase().replaceAll(' ', '_');
  const aliases = {
    'MENUNGGU_PEMBAYARAN': 'Menunggu Pembayaran',
    'MENUNGGU_KONFIRMASI_MITRA': 'Menunggu Mitra',
    'DITERIMA_MITRA': 'Diterima Mitra',
    'DIKIRIM_KE_PELAYAN': 'Dikirim ke Pelayan',
    'DITERIMA_PELAYAN': 'Diterima Pelayan',
    'MENUJU_LOKASI': 'Menuju Lokasi',
    'SEDANG_DIKERJAKAN': 'Sedang Dikerjakan',
    'SELESAI': 'Selesai',
    'DIBATALKAN': 'Dibatalkan',
    'DITOLAK_MITRA': 'Ditolak Mitra',
    'DITOLAK_PELAYAN': 'Ditolak Pelayan',
  };
  return aliases[normalized] ?? status.trim();
}

Color _historyStatusColor(String status) {
  if (_isCompletedStatus(status)) return const Color(0xFF25A777);
  if (status == 'Menunggu Pembayaran') return const Color(0xFFD99C18);
  if (_isCancelledStatus(status)) return const Color(0xFF6E7893);
  return _historyBlue;
}

Color _historyFooterColor(String status) {
  if (_isCompletedStatus(status)) return const Color(0xFFF2FBF7);
  if (status == 'Menunggu Pembayaran') return const Color(0xFFFFF9E9);
  if (_isCancelledStatus(status)) return const Color(0xFFF3F6FC);
  return const Color(0xFFF3F6FF);
}

String _historyFooterText(String status, List<Riwayat> histories) {
  if (_isCompletedStatus(status)) {
    final completed = _latestHistoryFor(
      histories,
      const {'Selesai'},
    );
    if (completed == null) return 'Pesanan telah selesai.';
    return 'Selesai pada ${_formatHistoryDate(completed.createdAt)}';
  }

  if (_isCancelledStatus(status)) {
    final cancelled = _latestHistoryFor(
      histories,
      const {'Dibatalkan', 'Ditolak Mitra', 'Ditolak Pelayan'},
    );
    if (cancelled == null) return 'Pesanan dibatalkan.';
    return '${cancelled.status} pada ${_formatHistoryDate(cancelled.createdAt)}';
  }

  return switch (status) {
    'Menunggu Pembayaran' => 'Menunggu pembayaran Anda',
    'Menunggu Mitra' => 'Menunggu konfirmasi dari mitra',
    'Diterima Mitra' => 'Mitra sedang menyiapkan pelayan',
    'Dikirim ke Pelayan' => 'Pesanan sudah dikirim ke pelayan',
    'Diterima Pelayan' => 'Pelayan sudah menerima tugas',
    'Menuju Lokasi' => 'Pelayan sedang menuju lokasi Anda',
    'Sedang Dikerjakan' => 'Layanan sedang dikerjakan',
    _ => 'Status booking mengikuti pembaruan terbaru',
  };
}

String? _historyFooterAction(String status, List<Riwayat> histories) {
  if (!_isCancelledStatus(status)) return null;
  final cancelled = _latestHistoryFor(
    histories,
    const {'Dibatalkan', 'Ditolak Mitra', 'Ditolak Pelayan'},
  );
  if (cancelled == null) return null;
  return cancelled.description.trim().isEmpty ? null : 'Lihat Alasan';
}

bool _isCompletedStatus(String status) => status == 'Selesai';

bool _isCancelledStatus(String status) =>
    status == 'Dibatalkan' ||
    status == 'Ditolak Mitra' ||
    status == 'Ditolak Pelayan';

Riwayat? _latestHistoryFor(List<Riwayat> histories, Set<String> statuses) {
  final matches = histories.where((item) => statuses.contains(item.status));
  if (matches.isEmpty) return null;
  final sorted = matches.toList()
    ..sort(
      (a, b) => _parseHistoryDate(b.createdAt).compareTo(
        _parseHistoryDate(a.createdAt),
      ),
    );
  return sorted.first;
}

DateTime _parseHistoryDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed != null) return parsed.toLocal();
  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _formatHistoryDate(String value) {
  final parsed = _parseHistoryDate(value);
  if (parsed.millisecondsSinceEpoch == 0) return '-';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}
