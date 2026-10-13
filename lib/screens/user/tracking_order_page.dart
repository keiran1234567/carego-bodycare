import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/app_store.dart';
import '../../models/app_models.dart';
import '../../utils/app_routes.dart';
import '../../utils/formatters.dart';

const _purple = Color(0xFF6548EE);
const _ink = Color(0xFF151629);
const _muted = Color(0xFF666B85);
const _line = Color(0xFFE9E8F4);

class TrackingOrderPage extends StatefulWidget {
  const TrackingOrderPage({super.key});

  @override
  State<TrackingOrderPage> createState() => _TrackingOrderPageState();
}

class _TrackingOrderPageState extends State<TrackingOrderPage> {
  String? requestedId;
  var loading = false;

  @override
  void initState() {
    super.initState();
    AppStore.instance.refreshBookings(silent: true).then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {
      // Keep the latest cached status when the server is temporarily offline.
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    requestedId ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<void> _refresh() async {
    setState(() => loading = true);
    try {
      await AppStore.instance.refreshBookings();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    if (store.bookings.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Status Pesanan')),
        body: Center(
          child: FilledButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Muat Status Pesanan'),
          ),
        ),
      );
    }
    final booking = store.bookings.firstWhere(
      (item) => item.id == requestedId,
      orElse: () => store.bookings.first,
    );
    final service = _service(store, booking.serviceId);
    final partner = _partner(store, booking.partnerId);
    final employee = _employee(store, booking.employeeId);
    final payment = _payment(store, booking.id);
    final histories =
        store.histories.where((item) => item.bookingId == booking.id).toList();
    final paid =
        payment?.status == 'PAID' || booking.status != 'Menunggu Pembayaran';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  _Header(loading: loading, onRefresh: _refresh),
                  const SizedBox(height: 16),
                  _SuccessBanner(paid: paid, status: booking.status),
                  const SizedBox(height: 14),
                  _OrderFacts(booking: booking),
                  const SizedBox(height: 14),
                  _StatusPanel(
                    booking: booking,
                    payment: payment,
                    histories: histories,
                    employee: employee,
                  ),
                  const SizedBox(height: 14),
                  _OrderDetail(
                    booking: booking,
                    service: service,
                    partner: partner,
                    employee: employee,
                  ),
                  const SizedBox(height: 12),
                  const _Notice(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.loading, required this.onRefresh});

  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20)),
          const Expanded(
            child: Text('Status Pesanan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          ),
          TextButton.icon(
            onPressed: loading ? null : onRefresh,
            icon: loading
                ? const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Perbarui'),
            style: TextButton.styleFrom(foregroundColor: _ink),
          ),
        ],
      );
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.paid, required this.status});

  final bool paid;
  final String status;

  @override
  Widget build(BuildContext context) => _Surface(
        gradient: const LinearGradient(
            colors: [Color(0xFFF0ECFF), Color(0xFFFBFAFF)]),
        child: Row(children: [
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x226548EE), blurRadius: 18)
                ]),
            child: Icon(
                paid ? Icons.check_rounded : Icons.hourglass_top_rounded,
                size: 42,
                color: paid ? _purple : const Color(0xFFE0A527)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(paid ? 'Pembayaran Berhasil!' : 'Menunggu Pembayaran',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(
                paid
                    ? 'Terima kasih, pesanan Anda sedang kami proses.'
                    : 'Selesaikan pembayaran agar pesanan dapat diproses.',
                style:
                    const TextStyle(fontSize: 11, color: _muted, height: 1.4),
              ),
              const SizedBox(height: 9),
              Text('Status saat ini: $status',
                  style: const TextStyle(
                      color: _purple,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          const Icon(Icons.verified_user_rounded,
              color: Color(0xFF48D6B4), size: 58),
        ]),
      );
}

class _OrderFacts extends StatelessWidget {
  const _OrderFacts({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) => _Surface(
        child: Row(
          children: [
            _Fact(label: 'Order ID', value: 'CG-${booking.id.padLeft(6, '0')}'),
            _Fact(label: 'Tanggal', value: booking.date),
            _Fact(label: 'Waktu', value: booking.time),
            _Fact(
                label: 'Total Pembayaran',
                value: AppFormatters.currency(booking.total),
                emphasized: true),
          ],
        ),
      );
}

class _Fact extends StatelessWidget {
  const _Fact(
      {required this.label, required this.value, this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: _line))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 9, color: _muted)),
            const SizedBox(height: 5),
            Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    color: emphasized ? _purple : _ink,
                    fontWeight: FontWeight.w900)),
          ]),
        ),
      );
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel(
      {required this.booking,
      required this.payment,
      required this.histories,
      required this.employee});

  final Booking booking;
  final Pembayaran? payment;
  final List<Riwayat> histories;
  final Pelayan? employee;

  @override
  Widget build(BuildContext context) {
    final stages =
        _stages(booking.status, payment?.status == 'PAID', histories);
    return _Surface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Status Pesanan',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        ...stages.asMap().entries.map((entry) => _TimelineItem(
            stage: entry.value, last: entry.key == stages.length - 1)),
        if (employee != null) ...[
          const Divider(height: 26, color: _line),
          Row(children: [
            _PersonAvatar(employee: employee!),
            const SizedBox(width: 11),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Pelayan Anda',
                      style: TextStyle(fontSize: 9, color: _muted)),
                  Text(employee!.name,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text('⭐ ${employee!.rating.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 10)),
                ])),
            CircleAvatar(
              backgroundColor: const Color(0xFFF0ECFF),
              child: IconButton(
                onPressed: _chatEnabled(booking.status)
                    ? () => Navigator.pushNamed(context, AppRoutes.chat,
                        arguments: booking.id)
                    : null,
                icon: const Icon(Icons.chat_outlined, color: _purple),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}

bool _chatEnabled(String status) => const {
      'Dikirim ke Pelayan',
      'Diterima Pelayan',
      'Pelayan Menuju Lokasi',
      'Sedang Dikerjakan',
      'Selesai',
    }.contains(status);

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.stage, required this.last});

  final _Stage stage;
  final bool last;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 42,
            child: Column(children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: stage.done || stage.active
                    ? _purple
                    : const Color(0xFFF0F0F4),
                child: Icon(stage.icon,
                    size: 17,
                    color: stage.done || stage.active
                        ? Colors.white
                        : const Color(0xFF8C8F9B)),
              ),
              if (!last)
                Expanded(
                    child: Container(
                        width: 2,
                        color: stage.done
                            ? const Color(0xFFA99AF7)
                            : const Color(0xFFE1E1E8))),
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(stage.title,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w900))),
                      if (stage.active)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF0ECFF),
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('Sedang Diproses',
                              style: TextStyle(
                                  color: _purple,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800)),
                        ),
                    ]),
                    if (stage.time.isNotEmpty)
                      Text(stage.time,
                          style: const TextStyle(fontSize: 9, color: _muted)),
                    const SizedBox(height: 3),
                    Text(stage.description,
                        style: const TextStyle(
                            fontSize: 9, color: _muted, height: 1.35)),
                  ]),
            ),
          ),
        ]),
      );
}

class _OrderDetail extends StatelessWidget {
  const _OrderDetail(
      {required this.booking,
      required this.service,
      required this.partner,
      required this.employee});

  final Booking booking;
  final Layanan? service;
  final Mitra? partner;
  final Pelayan? employee;

  @override
  Widget build(BuildContext context) => _Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
                child: Text('Detail Pesanan',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
            TextButton(
                onPressed: () => Navigator.pushNamed(
                    context, AppRoutes.bookingDetail,
                    arguments: booking.id),
                child: const Text('Lihat Detail')),
          ]),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(_serviceImage(service),
                  width: 105, height: 92, fit: BoxFit.cover),
            ),
            const SizedBox(width: 13),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(service?.name ?? 'Layanan',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 7),
                  Text('🏪 ${partner?.name ?? '-'}',
                      style: const TextStyle(fontSize: 10, color: _muted)),
                  Text('👤 ${employee?.name ?? '-'}',
                      style: const TextStyle(fontSize: 10, color: _muted)),
                  Text('📅 ${booking.date}   ◷ ${booking.time}',
                      style: const TextStyle(fontSize: 10, color: _muted)),
                  const SizedBox(height: 7),
                  Text(AppFormatters.currency(booking.total),
                      style: const TextStyle(
                          color: _purple, fontWeight: FontWeight.w900)),
                ])),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFFAFAFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _line)),
            child: Text('📍 ${booking.address}',
                style: const TextStyle(fontSize: 10, height: 1.4)),
          ),
        ]),
      );
}

class _Notice extends StatelessWidget {
  const _Notice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFFF0ECFF),
            borderRadius: BorderRadius.circular(14)),
        child: const Row(children: [
          Icon(Icons.notifications_none_rounded, color: _purple),
          SizedBox(width: 10),
          Expanded(
              child: Text(
                  'Kami akan mengirimkan notifikasi jika ada update terbaru.',
                  style: TextStyle(fontSize: 10, color: _purple))),
        ]),
      );
}

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({required this.employee});

  final Pelayan employee;

  @override
  Widget build(BuildContext context) => employee.photoUrl.isNotEmpty
      ? CircleAvatar(
          radius: 27, backgroundImage: NetworkImage(employee.photoUrl))
      : CircleAvatar(
          radius: 27,
          backgroundColor: const Color(0xFFE7E3FA),
          child: Text(_initials(employee.name),
              style: const TextStyle(
                  color: _purple, fontWeight: FontWeight.w900)));
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.gradient});

  final Widget child;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: gradient == null ? Colors.white : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0EFF8)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D5C50E6), blurRadius: 18, offset: Offset(0, 5))
          ],
        ),
        child: child,
      );
}

class _Stage {
  const _Stage(this.title, this.description, this.icon,
      {required this.done, required this.active, this.time = ''});

  final String title;
  final String description;
  final IconData icon;
  final bool done;
  final bool active;
  final String time;
}

List<_Stage> _stages(String status, bool paymentPaid, List<Riwayat> histories) {
  const order = [
    'Menunggu Pembayaran',
    'Menunggu Mitra',
    'Diterima Mitra',
    'Dikirim ke Pelayan',
    'Diterima Pelayan',
    'Pelayan Menuju Lokasi',
    'Sedang Dikerjakan',
    'Selesai',
  ];
  final current = order.indexOf(status).clamp(0, order.length - 1);
  final data = [
    ('Pesanan Dibuat', 'Pesanan Anda telah dibuat.', Icons.check_rounded, 0),
    (
      'Pembayaran Berhasil',
      'Pembayaran Anda telah berhasil.',
      Icons.check_rounded,
      1
    ),
    (
      'Mitra Dikonfirmasi',
      'Mitra sedang memproses pesanan Anda.',
      Icons.storefront_rounded,
      2
    ),
    (
      'Pelayan Ditugaskan',
      'Pelayan terbaik telah disiapkan untuk Anda.',
      Icons.person_outline_rounded,
      3
    ),
    (
      'Pelayan Menuju Lokasi',
      'Pelayan akan segera berangkat.',
      Icons.directions_car_outlined,
      5
    ),
    (
      'Layanan Berlangsung',
      'Layanan sedang dikerjakan di lokasi Anda.',
      Icons.calendar_month_outlined,
      6
    ),
    (
      'Layanan Selesai',
      'Terima kasih telah menggunakan layanan kami.',
      Icons.check_rounded,
      7
    ),
  ];
  return data.map((item) {
    final achieved = item.$4 == 1 ? paymentPaid : current >= item.$4;
    final active = item.$4 == 1
        ? !paymentPaid
        : (item.$4 <= 2 ? current < item.$4 : current == item.$4 - 1);
    final history = histories.where((entry) {
      if (item.$4 == 0) return true;
      if (item.$4 == 2) {
        return entry.status == 'Menunggu Mitra' ||
            entry.status == 'Diterima Mitra';
      }
      return order.indexOf(entry.status) >= item.$4;
    }).toList();
    return _Stage(item.$1, item.$2, item.$3,
        done: achieved,
        active: !achieved && active,
        time: history.isEmpty ? '' : _formatTimestamp(history.last.createdAt));
  }).toList();
}

Layanan? _service(AppStore store, String id) {
  final index = store.layanans.indexWhere((item) => item.id == id);
  return index < 0 ? null : store.layanans[index];
}

Mitra? _partner(AppStore store, String id) {
  final index = store.mitras.indexWhere((item) => item.id == id);
  return index < 0 ? null : store.mitras[index];
}

Pelayan? _employee(AppStore store, String id) {
  final index = store.pelayans.indexWhere((item) => item.id == id);
  return index < 0 ? null : store.pelayans[index];
}

Pembayaran? _payment(AppStore store, String bookingId) {
  final index =
      store.payments.indexWhere((item) => item.bookingId == bookingId);
  return index < 0 ? null : store.payments[index];
}

String _serviceImage(Layanan? service) {
  final value =
      '${service?.name ?? ''} ${service?.category ?? ''}'.toLowerCase();
  if (value.contains('nail')) return 'assets/images/service_nail_care.png';
  if (value.contains('facial') || value.contains('wajah')) {
    return 'assets/images/service_facial_glow.png';
  }
  if (value.contains('cukur') || value.contains('haircut')) {
    return 'assets/images/service_premium_haircut.png';
  }
  return 'assets/images/service_hair_treatment.png';
}

String _initials(String value) => value
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();

String _formatTimestamp(String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return '';
  return '${date.day}/${date.month}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
