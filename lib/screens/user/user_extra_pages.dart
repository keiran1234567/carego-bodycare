import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../data/user_ui_dummy_data.dart';
import '../../utils/app_routes.dart';
import '../../utils/formatters.dart';
import '../../widgets/user_ui_widgets.dart';

class ServiceDetailPage extends StatelessWidget {
  const ServiceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UserPage(
      bottom: BottomActionBar(
        primaryLabel: 'Pilih Mitra',
        secondaryLabel: 'Favorit',
        secondaryIcon: Icons.favorite_border_rounded,
        onSecondary: () =>
            Navigator.pushNamed(context, AppRoutes.userFavorites),
        onPrimary: () =>
            Navigator.pushNamed(context, AppRoutes.userMitraDetail),
      ),
      children: [
        const CustomHeader(title: 'Detail Layanan'),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            uiHeroImage,
            height: 210,
            width: double.infinity,
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Facial Basic',
          style: TextStyle(
            color: userInk,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: Color(0xFFFFB827), size: 20),
                Text(' 4.8 (128 ulasan)', style: TextStyle(color: userMuted)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, color: userMuted, size: 18),
                Text(' 60 Menit', style: TextStyle(color: userMuted)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniBadge('Home Service'),
            _MiniBadge('Kulit kusam'),
            _MiniBadge('Deep cleansing'),
            _MiniBadge('Relaxing'),
          ],
        ),
        const SizedBox(height: 18),
        const SoftCard(
          child: Text(
            'Perawatan wajah dasar untuk membersihkan, menyegarkan, dan membantu kulit terlihat lebih sehat. Cocok untuk perawatan rutin di rumah dengan terapis profesional.',
            style: TextStyle(color: userMuted, height: 1.55),
          ),
        ),
        const SectionTitle(title: 'Yang Anda Dapatkan'),
        const SoftCard(
          child: Column(
            children: [
              _BenefitLine(Icons.clean_hands_outlined, 'Pembersihan wajah'),
              _BenefitLine(Icons.spa_outlined, 'Masker dan relaksasi ringan'),
              _BenefitLine(Icons.verified_outlined, 'Produk aman dan higienis'),
              _BenefitLine(Icons.home_outlined, 'Layanan datang ke rumah'),
            ],
          ),
        ),
        const SectionTitle(title: 'Mitra Rekomendasi'),
        SoftCard(
          child: InkWell(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.userMitraDetail),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    uiSalonImage,
                    width: 76,
                    height: 68,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Glow Beauty Home Service',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w900, color: userInk)),
                      SizedBox(height: 6),
                      Text('Rating 4.8 - 256 ulasan',
                          style: TextStyle(fontSize: 12, color: userMuted)),
                      SizedBox(height: 4),
                      Text('Jakarta Selatan - 2.4 km',
                          style: TextStyle(fontSize: 12, color: userMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: userMuted),
              ],
            ),
          ),
        ),
        const SectionTitle(title: 'Terapis Tersedia'),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: uiTherapists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) =>
                PelayanCard(therapist: uiTherapists[index]),
          ),
        ),
      ],
    );
  }
}

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => UserPage(
        children: [
          const CustomHeader(title: 'Favorit Saya'),
          const SizedBox(height: 14),
          const Text(
            'Layanan dan penyedia yang Anda simpan dari backend tampil di sini.',
            style: TextStyle(color: userMuted, height: 1.5),
          ),
          const SizedBox(height: 16),
          if (store.favorites.isEmpty)
            const SoftCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFF0EDFF),
                    child:
                        Icon(Icons.bookmark_border_rounded, color: userPrimary),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Belum ada favorit. Simpan layanan atau mitra agar mudah ditemukan kembali.',
                      style: TextStyle(color: userMuted, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ...store.favorites.map((favorite) {
            final item = favorite['layanan'] is Map
                ? Map<String, dynamic>.from(favorite['layanan'] as Map)
                : Map<String, dynamic>.from(
                    (favorite['mitra'] as Map?) ?? const {});
            final mitra = item['mitra'] is Map
                ? Map<String, dynamic>.from(item['mitra'] as Map)
                : <String, dynamic>{};
            final image = '${item['image_url'] ?? item['cover_url'] ?? ''}';
            return SoftCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: image.isEmpty
                        ? const SizedBox(
                            width: 72,
                            height: 72,
                            child: ColoredBox(
                              color: Color(0xFFF0EDFF),
                              child: Icon(Icons.favorite_rounded,
                                  color: userPrimary),
                            ),
                          )
                        : Image.network(image,
                            width: 72, height: 72, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item['name'] ?? 'Favorit CareGo'}',
                            style: const TextStyle(
                                fontSize: 16,
                                color: userInk,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('${mitra['name'] ?? item['address'] ?? ''}',
                            style: const TextStyle(color: userMuted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.favorite_rounded, color: userPrimary),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  @override
  void initState() {
    super.initState();
    AppStore.instance.refreshWallet(silent: true).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = AppStore.instance.wallet;
    final balance = double.tryParse('${wallet['balance'] ?? 0}')?.round() ?? 0;
    final transactions = (wallet['transactions'] as List?) ?? const [];
    return UserPage(
      children: [
        const CustomHeader(title: 'Dompet & Riwayat Refund'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF6548EE), Color(0xFF3159D8)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Saldo Dompet CareGo',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(AppFormatters.currency(balance),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
                'Refund dari pembatalan Mitra otomatis masuk ke saldo ini.',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 20),
        const SectionTitle(title: 'Riwayat Refund'),
        if (transactions.isEmpty)
          const SoftCard(child: Text('Belum ada transaksi dompet.'))
        else
          ...transactions.map((raw) {
            final item = Map<String, dynamic>.from(raw as Map);
            final amount =
                double.tryParse('${item['amount'] ?? 0}')?.round() ?? 0;
            return SoftCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F7F0),
                  child: Icon(Icons.currency_exchange_rounded,
                      color: Color(0xFF188A5B)),
                ),
                title: Text('${item['description'] ?? 'Transaksi Dompet'}'),
                subtitle: Text('${item['created_at'] ?? ''}'),
                trailing: Text('+ ${AppFormatters.currency(amount)}',
                    style: const TextStyle(
                        color: Color(0xFF188A5B), fontWeight: FontWeight.w900)),
              ),
            );
          }),
      ],
    );
  }
}

class SelectAddressPage extends StatefulWidget {
  const SelectAddressPage({super.key});

  @override
  State<SelectAddressPage> createState() => _SelectAddressPageState();
}

class _SelectAddressPageState extends State<SelectAddressPage> {
  var selected = 0;

  @override
  Widget build(BuildContext context) {
    final addresses = AppStore.instance.addresses;
    return UserPage(
      bottom: BottomActionBar(
        primaryLabel: 'Gunakan Alamat',
        onPrimary: () {
          if (addresses.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Tambahkan alamat terlebih dahulu.')));
            return;
          }
          Navigator.pop(context, addresses[selected]);
        },
      ),
      children: [
        const CustomHeader(title: 'Pilih Alamat'),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addresses),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Alamat'),
          ),
        ),
        if (addresses.isEmpty)
          const SoftCard(child: Text('Belum ada alamat dari backend.'))
        else
          ...List.generate(addresses.length, (index) {
            final item = addresses[index];
            final active = selected == index;
            return InkWell(
              onTap: () => setState(() => selected = index),
              borderRadius: BorderRadius.circular(14),
              child: SoftCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      active
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: active ? userPrimary : userMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${item['label'] ?? 'Alamat'}',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      color: userInk,
                                      fontWeight: FontWeight.w900)),
                              if (item['is_primary'] == true) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: userPrimary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text('Utama',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('${item['address'] ?? ''}',
                              style: const TextStyle(
                                  color: userMuted, height: 1.55)),
                          const SizedBox(height: 14),
                          Text(AppStore.instance.currentUser?.phone ?? '',
                              style: const TextStyle(color: userInk)),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_outlined,
                        color: active ? userPrimary : userMuted),
                  ],
                ),
              ),
            );
          }),
        const SoftCard(
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: userPrimary),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Informasi alamat hanya digunakan untuk keperluan layanan dan tidak akan dibagikan kepada pihak lain.',
                  style: TextStyle(color: userMuted, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CheckoutVoucherPage extends StatefulWidget {
  const CheckoutVoucherPage({super.key});

  @override
  State<CheckoutVoucherPage> createState() => _CheckoutVoucherPageState();
}

class _CheckoutVoucherPageState extends State<CheckoutVoucherPage> {
  var selected = 0;
  final code = TextEditingController();

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vouchers = AppStore.instance.vouchers;
    return UserPage(
      bottom: BottomActionBar(
        primaryLabel: 'Pakai Voucher',
        onPrimary: () => Navigator.pop(
            context,
            code.text.trim().isNotEmpty
                ? code.text.trim().toUpperCase()
                : vouchers.isEmpty
                    ? null
                    : vouchers[selected]['code']),
      ),
      children: [
        const CustomHeader(title: 'Voucher Checkout'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: code,
                decoration: const InputDecoration(
                  hintText: 'Masukkan kode voucher',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: () => setState(() {}),
                style: FilledButton.styleFrom(backgroundColor: userPrimary),
                child: const Text('Gunakan'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (vouchers.isEmpty)
          const SoftCard(child: Text('Belum ada voucher aktif dari backend.'))
        else
          ...List.generate(vouchers.length, (index) {
            final item = vouchers[index];
            final active = selected == index;
            return InkWell(
              onTap: () => setState(() => selected = index),
              borderRadius: BorderRadius.circular(14),
              child: SoftCard(
                padding: EdgeInsets.zero,
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      height: 128,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD9BEFF),
                        borderRadius:
                            BorderRadius.horizontal(left: Radius.circular(14)),
                      ),
                      child: const Icon(Icons.confirmation_number_outlined,
                          color: Colors.white, size: 42),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('${item['code'] ?? '-'}',
                                      style: const TextStyle(
                                          color: userInk,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900)),
                                ),
                                Icon(
                                  active
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: active ? userPrimary : userMuted,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('${item['name'] ?? item['description'] ?? ''}',
                                style: const TextStyle(
                                    color: userInk,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text(
                                'Min. transaksi Rp${item['min_transaction'] ?? 0}',
                                style: const TextStyle(color: userMuted)),
                            const SizedBox(height: 14),
                            Text(active ? 'Terpilih' : 'S&K',
                                style: const TextStyle(
                                    color: userPrimary,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
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

class PaymentStatusPage extends StatelessWidget {
  const PaymentStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UserPage(
      children: [
        const CustomHeader(title: 'Status Pembayaran'),
        const SizedBox(height: 24),
        const SoftCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: Color(0xFFE7F8EF),
                child: Icon(Icons.check_circle_rounded,
                    color: Color(0xFF21A66D), size: 58),
              ),
              SizedBox(height: 18),
              Text('Pembayaran Berhasil',
                  style: TextStyle(
                      color: userInk,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text('Transaksi Midtrans Anda berhasil diproses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: userMuted)),
              SizedBox(height: 18),
              _StatusPaymentLine('Order ID', '#BC2405221420'),
              _StatusPaymentLine('Metode', 'QRIS Midtrans'),
              _StatusPaymentLine('Waktu', '22 Mei 2024, 13:35 WIB'),
              _StatusPaymentLine('Total', 'Rp120.000'),
            ],
          ),
        ),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.userTracking),
            style: FilledButton.styleFrom(backgroundColor: userPrimary),
            child: const Text('Lihat Tracking Pesanan'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.bookingDetail),
            child: const Text('Lihat Detail Booking'),
          ),
        ),
      ],
    );
  }
}

class CancelBookingPage extends StatelessWidget {
  const CancelBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    const reasons = [
      'Jadwal tidak cocok',
      'Ingin mengganti layanan',
      'Alamat layanan berubah',
      'Sudah mendapatkan layanan lain',
    ];
    return UserPage(
      bottom: BottomActionBar(
        primaryLabel: 'Batalkan Booking',
        primaryIcon: Icons.cancel_outlined,
        onPrimary: () => Navigator.pop(context),
      ),
      children: [
        const CustomHeader(title: 'Batalkan Booking'),
        const SizedBox(height: 14),
        const _BookingMiniCard(),
        const SectionTitle(title: 'Pilih Alasan'),
        ...reasons.map(
          (reason) => SoftCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.radio_button_unchecked_rounded,
                    color: userPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(reason,
                      style: const TextStyle(
                          color: userInk, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
        const SectionTitle(title: 'Catatan Tambahan'),
        const TextField(
          minLines: 4,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Tulis alasan tambahan jika diperlukan',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const SoftCard(
          child: Text(
            'Booking yang sudah dibatalkan akan masuk ke riwayat Dibatalkan. Refund mengikuti metode pembayaran dan status pesanan.',
            style: TextStyle(color: userMuted, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class RescheduleBookingPage extends StatefulWidget {
  const RescheduleBookingPage({super.key});

  @override
  State<RescheduleBookingPage> createState() => _RescheduleBookingPageState();
}

class _RescheduleBookingPageState extends State<RescheduleBookingPage> {
  var selectedDay = 1;
  var selectedTime = '15:00';

  @override
  Widget build(BuildContext context) {
    const times = ['09:00', '11:00', '13:00', '15:00', '17:00', '19:00'];
    return UserPage(
      bottom: BottomActionBar(
        primaryLabel: 'Simpan Jadwal Baru',
        onPrimary: () => Navigator.pop(context),
      ),
      children: [
        const CustomHeader(title: 'Ubah Jadwal'),
        const SizedBox(height: 14),
        const _BookingMiniCard(),
        const SectionTitle(title: 'Pilih Tanggal Baru'),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final active = selectedDay == index;
              return InkWell(
                onTap: () => setState(() => selectedDay = index),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 74,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: active ? userPrimary : Colors.white,
                    border: Border.all(color: active ? userPrimary : userLine),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          [
                            'Sen',
                            'Sel',
                            'Rab',
                            'Kam',
                            'Jum',
                            'Sab',
                            'Min'
                          ][index],
                          style: TextStyle(
                              color: active ? Colors.white : userMuted)),
                      const SizedBox(height: 5),
                      Text('${24 + index}',
                          style: TextStyle(
                              color: active ? Colors.white : userInk,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SectionTitle(title: 'Pilih Jam Baru'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: times.map((time) {
            final active = selectedTime == time;
            return InkWell(
              onTap: () => setState(() => selectedTime = time),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 96,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? userPrimary : Colors.white,
                  border: Border.all(color: userPrimary),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                      color: active ? Colors.white : userPrimary,
                      fontWeight: FontWeight.w900),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Text(
            'Jadwal baru: Selasa, ${24 + selectedDay} Mei 2024, $selectedTime WIB',
            style: const TextStyle(
                color: userInk, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class EmptyStatesPage extends StatelessWidget {
  const EmptyStatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const states = [
      (
        Icons.event_note_outlined,
        'Belum Ada Booking',
        'Mulai pilih layanan favorit dan booking pertama Anda.'
      ),
      (
        Icons.chat_bubble_outline_rounded,
        'Belum Ada Chat',
        'Percakapan dengan mitra dan pelayan akan tampil di sini.'
      ),
      (
        Icons.notifications_none_rounded,
        'Belum Ada Notifikasi',
        'Update booking, promo, dan sistem akan muncul di sini.'
      ),
      (
        Icons.favorite_border_rounded,
        'Belum Ada Favorit',
        'Simpan layanan atau mitra favorit agar mudah ditemukan.'
      ),
    ];
    return UserPage(
      children: [
        const CustomHeader(title: 'Empty State UI'),
        const SizedBox(height: 14),
        ...states.map(
          (item) => SoftCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: const Color(0xFFF0EDFF),
                  child: Icon(item.$1, color: userPrimary, size: 36),
                ),
                const SizedBox(height: 14),
                Text(item.$2,
                    style: const TextStyle(
                        color: userInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(item.$3,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: userMuted, height: 1.45)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0FF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(label,
            style: const TextStyle(
                color: userPrimary, fontWeight: FontWeight.w800)),
      );
}

class _BenefitLine extends StatelessWidget {
  const _BenefitLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: userPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: userInk, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class _StatusPaymentLine extends StatelessWidget {
  const _StatusPaymentLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(label, style: const TextStyle(color: userMuted)),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: userInk, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
}

class _BookingMiniCard extends StatelessWidget {
  const _BookingMiniCard();

  @override
  Widget build(BuildContext context) => SoftCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                uiHeroImage,
                width: 86,
                height: 86,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Facial Basic',
                      style: TextStyle(
                          color: userInk,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  SizedBox(height: 6),
                  Text('Glow Beauty Home Service',
                      style: TextStyle(color: userMuted)),
                  SizedBox(height: 6),
                  Text('Rabu, 22 Mei 2024 - 14:00 WIB',
                      style: TextStyle(color: userMuted)),
                ],
              ),
            ),
          ],
        ),
      );
}
