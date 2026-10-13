import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/app_store.dart';
import '../data/dummy_data.dart';
import '../utils/app_routes.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/info_card.dart';
import '../widgets/responsive_page.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  var cancelling = false;
  String? requestedId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    requestedId ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    if (store.bookings.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Booking')),
        body: const Center(child: Text('Belum ada booking dari server.')),
      );
    }

    final booking =
        store.bookings.where((item) => item.id == requestedId).firstOrNull ??
            store.bookings.first;
    final service = serviceById(booking.serviceId);
    final partner = partnerById(booking.partnerId);
    final employee = employeeById(booking.employeeId);
    final bookingHistories = historiesByBookingId(booking.id);
    final paymentMatches =
        payments.where((item) => item.bookingId == booking.id).toList();
    final payment = paymentMatches.isEmpty ? null : paymentMatches.first;

    return Theme(
      data: buildRoleBlueTheme(
        Theme.of(context),
        primary: const Color(0xFF225CD8),
        secondary: const Color(0xFF4D77F6),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text('Booking ${booking.id}')),
        body: ResponsivePage(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(child: Icon(service.icon)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900)),
                          Text(partner.name),
                        ],
                      ),
                    ),
                    Chip(label: Text(booking.status)),
                  ]),
                  const Divider(),
                  _Line('Jadwal', '${booking.date} ${booking.time}'),
                  _Line('Alamat', booking.address),
                  _Line(
                      'Catatan',
                      booking.note.isEmpty
                          ? 'Tidak ada catatan'
                          : booking.note),
                  _Line('Pelayan', '${employee.name} - ${employee.specialty}'),
                  _Line('Subtotal', AppFormatters.currency(booking.subtotal)),
                  _Line('Biaya perjalanan',
                      AppFormatters.currency(booking.travelFee)),
                  if (booking.discount > 0)
                    _Line('Diskon',
                        '- ${AppFormatters.currency(booking.discount)}'),
                  _Line('Total', AppFormatters.currency(booking.total)),
                  _Line('Pembayaran',
                      payment == null ? 'Belum dibuat' : payment.status),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Riwayat Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (bookingHistories.isEmpty)
              const InfoCard(child: Text('Riwayat belum tersedia.'))
            else
              ...bookingHistories.map((history) => InfoCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline_rounded),
                      title: Text(history.title),
                      subtitle: Text(history.description),
                      trailing: Text(history.createdAt,
                          style: const TextStyle(fontSize: 10)),
                    ),
                  )),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _chatAllowed(booking.status)
                      ? () => Navigator.pushNamed(context, AppRoutes.chat,
                          arguments: booking.id)
                      : null,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Chat'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: cancelling ||
                          booking.status == 'Selesai' ||
                          booking.status == 'Dibatalkan'
                      ? null
                      : () => _cancel(booking.id),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(cancelling ? 'Membatalkan...' : 'Batalkan'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _cancel(String bookingId) async {
    setState(() => cancelling = true);
    try {
      await AppStore.instance.cancelBooking(bookingId);
      if (mounted) setState(() {});
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => cancelling = false);
    }
  }
}

bool _chatAllowed(String status) => const {
      'Dikirim ke Pelayan',
      'Diterima Pelayan',
      'Pelayan Menuju Lokasi',
      'Sedang Dikerjakan',
      'Selesai',
    }.contains(status);

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 100,
              child:
                  Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );
}
