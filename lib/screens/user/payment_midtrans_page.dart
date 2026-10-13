import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/api_client.dart';
import '../../data/app_store.dart';
import '../../utils/app_routes.dart';
import '../../utils/formatters.dart';
import '../../widgets/user_ui_widgets.dart';

class PaymentMidtransPage extends StatefulWidget {
  const PaymentMidtransPage({super.key});

  @override
  State<PaymentMidtransPage> createState() => _PaymentMidtransPageState();
}

class _PaymentMidtransPageState extends State<PaymentMidtransPage>
    with WidgetsBindingObserver {
  static const _browser = MethodChannel('carego/browser');
  var paying = false;
  var checking = false;
  var loading = true;
  String? activeBookingId;
  String? requestedBookingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBooking());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    requestedBookingId ??=
        ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<void> _loadBooking() async {
    try {
      await AppStore.instance.refreshBookings(silent: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && activeBookingId != null) {
      _checkStatus(activeBookingId!);
    }
  }

  Future<void> _pay() async {
    final store = AppStore.instance;
    final payable = _payableBookings(store);
    if (payable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak ada booking yang menunggu pembayaran.')),
      );
      return;
    }
    setState(() => paying = true);
    try {
      activeBookingId = payable.first.id;
      final payment = await store.createPayment(activeBookingId!);
      if (!mounted) return;
      final paymentStatus =
          '${payment['status_pembayaran'] ?? ''}'.toUpperCase();
      if (paymentStatus == 'PAID') {
        final bookingId = activeBookingId!;
        activeBookingId = null;
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.userPaymentStatus,
          arguments: bookingId,
        );
        return;
      }
      final redirectUrl = payment['redirect_url'] as String?;
      if (redirectUrl == null || redirectUrl.isEmpty) {
        throw const ApiException(
          'Link pembayaran Midtrans tidak tersedia. Periksa konfigurasi server.',
        );
      }
      await _browser.invokeMethod<void>('openUrl', {'url': redirectUrl});
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Browser gagal dibuka.')),
      );
    } finally {
      if (mounted) setState(() => paying = false);
    }
  }

  Future<void> _checkStatus(String bookingId) async {
    if (checking) return;
    setState(() => checking = true);
    try {
      final paid = await AppStore.instance.syncPayment(bookingId);
      if (!mounted) return;
      if (paid) {
        activeBookingId = null;
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.userPaymentStatus,
          arguments: bookingId,
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pembayaran belum terkonfirmasi. Jika baru membayar, coba lagi beberapa detik.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payable = _payableBookings(AppStore.instance);
    final booking = payable.isEmpty ? null : payable.first;
    final total = booking?.total ?? 0;
    const methods = [
      ('QRIS', Icons.qr_code_rounded, Color(0xFF5B35D5)),
      ('GoPay', Icons.account_balance_wallet_rounded, Color(0xFF18AFD0)),
      ('OVO', Icons.circle_outlined, Color(0xFF6C2BCB)),
      ('DANA', Icons.wallet_rounded, Color(0xFF2D8BEE)),
      ('ShopeePay', Icons.shopping_bag_outlined, Color(0xFFF05A32)),
      ('Bank Transfer BCA', Icons.account_balance_rounded, Color(0xFF2347BB)),
      (
        'Bank Transfer Mandiri',
        Icons.account_balance_rounded,
        Color(0xFFE7A51A)
      ),
      ('Bank Transfer BNI', Icons.account_balance_rounded, Color(0xFFE86D23)),
    ];
    return UserPage(
      children: [
        const CustomHeader(title: 'Pembayaran'),
        const SizedBox(height: 18),
        SoftCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total Pembayaran', style: TextStyle(color: userMuted)),
          const SizedBox(height: 8),
          Text(AppFormatters.currency(total),
              style: const TextStyle(
                  color: userPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
              loading
                  ? 'Memuat booking dari server...'
                  : booking == null
                      ? 'Buat booking terlebih dahulu untuk melanjutkan pembayaran.'
                      : 'Pembayaran booking #${booking.id} akan diproses melalui Midtrans.',
              style: const TextStyle(color: userMuted))
        ])),
        if (!loading && booking == null) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.booking,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Booking Sekarang'),
            ),
          ),
        ],
        const SectionTitle(title: 'Metode Pembayaran Tersedia'),
        ...methods.map((method) => PaymentMethodCard(
            title: method.$1, icon: method.$2, color: method.$3)),
        const SoftCard(
            child: Row(children: [
          Icon(Icons.lock_outline_rounded, color: userPrimary),
          SizedBox(width: 12),
          Expanded(
              child: Text(
                  'Pembayaran aman dan terenkripsi oleh Midtrans. Tidak ada input kartu manual di aplikasi.',
                  style: TextStyle(color: userMuted, height: 1.4)))
        ])),
        const SizedBox(height: 10),
        SizedBox(
            height: 54,
            child: FilledButton(
                onPressed: loading || paying || booking == null ? null : _pay,
                style: FilledButton.styleFrom(backgroundColor: userPrimary),
                child: Text(paying
                    ? 'Memproses Pembayaran...'
                    : 'Bayar dengan Midtrans'))),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: loading || checking || booking == null
                ? null
                : () => _checkStatus(booking.id),
            icon: checking
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            label: Text(checking
                ? 'Mengecek Pembayaran...'
                : 'Saya Sudah Bayar, Cek Status'),
          ),
        ),
      ],
    );
  }

  List<dynamic> _payableBookings(AppStore store) {
    final payable = store.bookings
        .where((booking) => booking.status == 'Menunggu Pembayaran')
        .toList();
    if (requestedBookingId == null) return payable;
    payable.sort((a, b) {
      if (a.id == requestedBookingId) return -1;
      if (b.id == requestedBookingId) return 1;
      return 0;
    });
    return payable;
  }
}
