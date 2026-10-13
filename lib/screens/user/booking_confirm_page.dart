import 'package:flutter/material.dart';

import '../../data/user_ui_dummy_data.dart';
import '../../utils/app_routes.dart';
import '../../widgets/user_ui_widgets.dart';

class BookingConfirmPage extends StatelessWidget {
  const BookingConfirmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UserPage(
      children: [
        const CustomHeader(title: 'Konfirmasi Booking'),
        const SizedBox(height: 18),
        const _Stepper(),
        const SizedBox(height: 18),
        const SoftCard(
            child: Text(
                'Mohon periksa kembali detail booking Anda sebelum melanjutkan ke pembayaran.',
                style: TextStyle(color: userMuted))),
        _SummaryCard(
            title: 'Ringkasan Layanan',
            icon: Icons.spa_outlined,
            action: 'Ubah',
            onAction: () =>
                Navigator.pushNamed(context, AppRoutes.userServiceDetail),
            child: const _ServiceSummary()),
        const _SummaryCard(
            title: 'Mitra / Salon',
            icon: Icons.storefront_outlined,
            action: 'Ubah',
            child: Text(
                'Glow Beauty Home Service\nRating 4.8 (256 ulasan)\nJl. Kemang Raya No. 15, Jakarta Selatan',
                style: TextStyle(color: userMuted, height: 1.5))),
        const _SummaryCard(
            title: 'Pelayan / Terapis',
            icon: Icons.person_outline_rounded,
            action: 'Ubah',
            child: Text(
                'Sinta Aprilia\nTerapis Kecantikan\nRating 4.9 (128 ulasan)  -  3 tahun pengalaman',
                style: TextStyle(color: userMuted, height: 1.5))),
        _SummaryCard(
            title: 'Jadwal Booking',
            icon: Icons.calendar_month_outlined,
            action: 'Ubah',
            onAction: () =>
                Navigator.pushNamed(context, AppRoutes.userRescheduleBooking),
            child: const Text(
                'Tanggal: Rabu, 22 Mei 2024\nWaktu: 14:00 WIB\nDurasi: 60 Menit',
                style: TextStyle(color: userMuted, height: 1.5))),
        _SummaryCard(
            title: 'Alamat Layanan',
            icon: Icons.location_on_outlined,
            action: 'Ubah',
            onAction: () =>
                Navigator.pushNamed(context, AppRoutes.userSelectAddress),
            child: const Text(
                'Jl. Kemang Raya No. 15\nBangka, Mampang Prapatan, Jakarta Selatan 12730',
                style: TextStyle(color: userMuted, height: 1.5))),
        const _SummaryCard(
            title: 'Catatan untuk Terapis (Opsional)',
            icon: Icons.notes_outlined,
            action: 'Ubah',
            child: Text(
                'Fokus di area komedo dan kulit sensitif. Terima kasih.',
                style: TextStyle(color: userMuted))),
        _SummaryCard(
            title: 'Voucher',
            icon: Icons.confirmation_number_outlined,
            action: 'Pilih',
            onAction: () =>
                Navigator.pushNamed(context, AppRoutes.userCheckoutVoucher),
            child: const Text(
                'DISKON20 tersedia untuk pesanan ini. Pilih voucher untuk melihat potongan harga.',
                style: TextStyle(color: userMuted, height: 1.5))),
        SoftCard(
            child: Row(children: [
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Total Pembayaran',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, color: userInk)),
                Text('Rp120.000',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        color: userPrimary))
              ])),
          Expanded(
              child: SizedBox(
                  height: 54,
                  child: FilledButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.userPayment),
                      style:
                          FilledButton.styleFrom(backgroundColor: userPrimary),
                      child: const Text('Lanjutkan ke Pembayaran'))))
        ])),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper();
  @override
  Widget build(BuildContext context) => Row(
      children: ['Layanan', 'Pelayan', 'Jadwal', 'Konfirmasi']
          .asMap()
          .entries
          .map((entry) => Expanded(
                child: Column(children: [
                  CircleAvatar(
                      radius: 18,
                      backgroundColor: userPrimary,
                      child: entry.key == 3
                          ? const Text('4',
                              style: TextStyle(color: Colors.white))
                          : const Icon(Icons.check_rounded,
                              color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(entry.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: entry.key == 3
                              ? FontWeight.w900
                              : FontWeight.w500))
                ]),
              ))
          .toList());
}

class _ServiceSummary extends StatelessWidget {
  const _ServiceSummary();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 430;
      final image = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(uiHeroImage,
            width: compact ? 88 : 120,
            height: compact ? 88 : 96,
            fit: BoxFit.cover,
            alignment: Alignment.centerRight),
      );
      const details = Text(
          'Facial Basic\nPerawatan wajah dasar untuk membersihkan dan menyegarkan kulit.\n60 Menit - Home Service',
          style: TextStyle(color: userMuted, height: 1.45));
      if (compact) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            image,
            const SizedBox(width: 12),
            const Expanded(child: details),
          ]),
          const SizedBox(height: 12),
          const Text('Rp120.000',
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18, color: userInk)),
        ]);
      }
      return Row(children: [
        image,
        const SizedBox(width: 16),
        const Expanded(child: details),
        const Text('Rp120.000',
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 18, color: userInk))
      ]);
    });
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.title,
      required this.icon,
      required this.action,
      required this.child,
      this.onAction});
  final String title;
  final IconData icon;
  final String action;
  final Widget child;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => SoftCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: userPrimary),
          const SizedBox(width: 10),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: userInk,
                      fontSize: 16))),
          TextButton(
            onPressed: onAction,
            child: Text(action,
                style: const TextStyle(
                    color: userPrimary, fontWeight: FontWeight.w900)),
          )
        ]),
        const SizedBox(height: 14),
        child
      ]));
}
