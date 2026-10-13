import 'package:flutter/material.dart';

import '../data/app_store.dart';
import 'location_address_screen.dart';

const _subPurple = Color(0xFF6138E5);
const _subInk = Color(0xFF11173F);
const _subMuted = Color(0xFF69708F);
const _subLine = Color(0xFFE5E7F0);

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final store = AppStore.instance;

  Future<void> _addAddress() async {
    await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => const LocationAddressScreen()));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => _SubPage(
        title: 'Alamat Saya',
        action: TextButton.icon(
            onPressed: _addAddress,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Alamat')),
        children: [
          if (store.addresses.isEmpty)
            const _InfoBanner(
                icon: Icons.location_off_outlined,
                title: 'Belum ada alamat',
                body: 'Tambahkan alamat agar proses booking lebih cepat.'),
          ...store.addresses.map((item) => _AddressCard(
                title: '${item['label'] ?? 'Alamat'}',
                address: '${item['address'] ?? ''}',
                contact: store.currentUser?.phone ?? '',
                selected: item['is_primary'] == true,
              )),
          const _InfoBanner(
              icon: Icons.shield_outlined,
              title: 'Alamat Aman & Terlindungi',
              body:
                  'Informasi alamat hanya digunakan untuk keperluan layanan.'),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard(
      {required this.title,
      required this.address,
      required this.contact,
      required this.selected});
  final String title;
  final String address;
  final String contact;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 68),
            child: Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? _subPurple : _subMuted,
                size: 25),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selected)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF7649EB), Color(0xFF5427D7)]),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('Utama',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                Text(title,
                    style: const TextStyle(
                        color: _subInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Text(address,
                    style: const TextStyle(
                        color: _subMuted, fontSize: 13, height: 1.55)),
                const SizedBox(height: 18),
                Text(contact,
                    style: const TextStyle(color: _subMuted, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, color: _subPurple)),
        ],
      ),
    );
  }
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SubPage(
      title: 'Metode Pembayaran',
      children: [
        _ListSectionHeader(title: 'E-Wallet', action: 'Tambah'),
        _PaymentRow(
            name: 'GoPay',
            number: '0812  **** ****  1234',
            icon: Icons.account_balance_wallet_rounded,
            color: Color(0xFF11B8DA),
            primary: true),
        _PaymentRow(
            name: 'OVO',
            number: '0812  **** ****  1234',
            icon: Icons.circle_outlined,
            color: Color(0xFF6E2BCB)),
        _PaymentRow(
            name: 'DANA',
            number: '0812  **** ****  1234',
            icon: Icons.wallet_rounded,
            color: Color(0xFF2387EE)),
        _PaymentRow(
            name: 'ShopeePay',
            number: '0812  **** ****  1234',
            icon: Icons.shopping_bag_outlined,
            color: Color(0xFFF04D2D)),
        SizedBox(height: 10),
        _ListSectionHeader(title: 'Kartu'),
        _PaymentRow(
            name: 'Visa    **** **** **** 1234',
            number: 'Keiran',
            icon: Icons.credit_card_rounded,
            color: Color(0xFF193DC8),
            primary: true),
        _PaymentRow(
            name: 'Mastercard    **** **** **** 5678',
            number: 'Keiran',
            icon: Icons.circle,
            color: Color(0xFFF5A423)),
        SizedBox(height: 10),
        _ListSectionHeader(title: 'Bank Transfer'),
        _PaymentRow(
            name: 'BCA    **** 1234',
            number: 'Keiran',
            icon: Icons.account_balance_rounded,
            color: Color(0xFF193DC8)),
        _PaymentRow(
            name: 'Mandiri    **** 5678',
            number: 'Keiran',
            icon: Icons.account_balance_rounded,
            color: Color(0xFFF5A423)),
        _InfoBanner(
            icon: Icons.shield_outlined,
            title: 'Pembayaran Anda aman dan terenkripsi',
            body: ''),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow(
      {required this.name,
      required this.number,
      required this.icon,
      required this.color,
      this.primary = false});
  final String name;
  final String number;
  final IconData icon;
  final Color color;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      compact: true,
      child: Row(
        children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: Colors.white)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: _subInk)),
                const SizedBox(height: 6),
                Text(number,
                    style: const TextStyle(color: _subInk, fontSize: 13))
              ])),
          if (primary)
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0EDFF),
                    borderRadius: BorderRadius.circular(7)),
                child: const Text('Utama',
                    style: TextStyle(
                        color: _subPurple,
                        fontSize: 11,
                        fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class PromoVoucherScreen extends StatefulWidget {
  const PromoVoucherScreen({super.key});

  @override
  State<PromoVoucherScreen> createState() => _PromoVoucherScreenState();
}

class _PromoVoucherScreenState extends State<PromoVoucherScreen> {
  final store = AppStore.instance;
  var history = false;

  @override
  Widget build(BuildContext context) {
    final items = history ? store.voucherHistory : store.vouchers;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => _SubPage(title: 'Promo & Voucher', children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
                value: false,
                label: Text('Voucher Aktif'),
                icon: Icon(Icons.discount_outlined)),
            ButtonSegment(
                value: true,
                label: Text('Riwayat'),
                icon: Icon(Icons.history_rounded)),
          ],
          selected: {history},
          onSelectionChanged: (value) => setState(() => history = value.first),
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          const _InfoBanner(
              icon: Icons.discount_outlined,
              title: 'Belum ada data voucher',
              body:
                  'Voucher aktif dan riwayat penggunaan akan tampil di sini.'),
        ...items.map((item) {
          final voucher = history && item['voucher'] is Map
              ? Map<String, dynamic>.from(item['voucher'] as Map)
              : item;
          return _VoucherCard(
            code: '${voucher['code'] ?? '-'}',
            title:
                '${voucher['name'] ?? voucher['description'] ?? 'Voucher CareGo'}',
            minimum: history
                ? 'Potongan Rp${item['discount_amount'] ?? 0}'
                : 'Min. transaksi Rp${voucher['min_transaction'] ?? 0}',
            expiry: history
                ? 'Sudah digunakan'
                : 'Berlaku hingga ${voucher['expires_at'] ?? 'tanpa batas'}',
          );
        }),
      ]),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard(
      {required this.code,
      required this.title,
      required this.minimum,
      required this.expiry});
  final String code;
  final String title;
  final String minimum;
  final String expiry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _subLine),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
              width: 112,
              height: 170,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFFE1C9FF), Color(0xFFB998F6)]),
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(11))),
              child: const Icon(Icons.local_activity_rounded,
                  color: Colors.white, size: 52)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(code,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _subInk)),
                    const SizedBox(height: 15),
                    Text(title,
                        style: const TextStyle(fontSize: 14, color: _subInk)),
                    const SizedBox(height: 10),
                    Text(minimum,
                        style: const TextStyle(fontSize: 12, color: _subMuted)),
                    const SizedBox(height: 22),
                    Row(children: [
                      Expanded(
                          child: Text(expiry,
                              style: const TextStyle(
                                  fontSize: 11, color: _subMuted))),
                      const Text('S&K',
                          style: TextStyle(
                              color: _subPurple, fontWeight: FontWeight.w900))
                    ])
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const topics = [
      (
        'Cara Booking Layanan',
        Icons.calendar_month_outlined,
        Color(0xFF2678EE)
      ),
      ('Metode Pembayaran', Icons.credit_card_outlined, Color(0xFF7248E8)),
      ('Pembatalan & Refund', Icons.event_busy_outlined, Color(0xFFF4A514)),
      ('Masalah Akun', Icons.shield_outlined, Color(0xFF2678EE)),
      ('Promo & Voucher', Icons.local_activity_outlined, Color(0xFF20B96A)),
      ('Akun & Keamanan', Icons.headset_mic_outlined, Color(0xFF7248E8)),
      ('Lainnya', Icons.chat_bubble_outline_rounded, Color(0xFF2678EE)),
    ];
    return _SubPage(
      title: 'Bantuan & Pusat Bantuan',
      children: [
        TextField(
            decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Cari bantuan...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _subLine)))),
        const SizedBox(height: 24),
        const _ListSectionHeader(title: 'Topik Bantuan'),
        const _MenuCard(items: topics),
        const SizedBox(height: 18),
        const _ListSectionHeader(title: 'Butuh Bantuan Lain?'),
        const _MenuCard(items: [
          (
            'Chat dengan CS',
            Icons.chat_bubble_outline_rounded,
            Color(0xFF7248E8)
          ),
          ('WhatsApp', Icons.phone_outlined, Color(0xFF20B96A)),
          ('Email', Icons.mail_outline_rounded, Color(0xFF2678EE))
        ]),
        const _InfoBanner(
            icon: Icons.verified_user_outlined,
            title: 'Keamanan Terjamin',
            body:
                'Data dan percakapan Anda aman bersama kami. Kami tidak akan membagikannya kepada pihak lain.'),
      ],
    );
  }
}

class AboutBodyCareScreen extends StatelessWidget {
  const AboutBodyCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Syarat & Ketentuan', Icons.description_outlined, Color(0xFF7248E8)),
      ('Kebijakan Privasi', Icons.lock_outline_rounded, Color(0xFF2678EE)),
      ('Lisensi', Icons.verified_user_outlined, Color(0xFF20B96A)),
      ('Tim Kami', Icons.people_outline_rounded, Color(0xFFF4A514)),
      ('Berita & Promo', Icons.campaign_outlined, Color(0xFFD94ADB)),
      ('Bagikan Aplikasi', Icons.share_outlined, Color(0xFF2678EE)),
    ];
    return _SubPage(
      title: 'Tentang BodyCare',
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
              color: const Color(0xFFF3F1FF),
              borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            CircleAvatar(
                radius: 58,
                backgroundColor: Color(0xFFE6E0FF),
                child: Icon(Icons.spa_outlined, size: 62, color: _subPurple)),
            SizedBox(width: 20),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('BodyCare Home Service',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _subInk)),
                  SizedBox(height: 10),
                  Text(
                      'Solusi perawatan kecantikan profesional di kenyamanan rumah Anda.',
                      style: TextStyle(
                          fontSize: 13, height: 1.5, color: _subMuted))
                ]))
          ]),
        ),
        const SizedBox(height: 22),
        const _MenuCard(items: items, large: true),
        const SizedBox(height: 28),
        const Text(
            '© 2024 BodyCare. All rights reserved.\n\nMade with love in Indonesia',
            textAlign: TextAlign.center,
            style: TextStyle(color: _subMuted, fontSize: 11)),
      ],
    );
  }
}

class _SubPage extends StatelessWidget {
  const _SubPage({required this.title, required this.children, this.action});
  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                LayoutBuilder(builder: (context, constraints) {
                  final compact = action != null && constraints.maxWidth < 360;
                  return Column(children: [
                    Row(children: [
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: _subInk)),
                      Expanded(
                          child: Text(title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: _subInk))),
                      SizedBox(width: compact || action == null ? 48 : 0),
                      if (action != null && !compact) action!
                    ]),
                    if (action != null && compact)
                      Align(alignment: Alignment.centerRight, child: action!),
                  ]);
                }),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, this.compact = false});
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _subLine),
          borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: _subPurple, size: 30),
        const SizedBox(width: 15),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w900, color: _subInk)),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(body,
                style: const TextStyle(
                    fontSize: 11, color: _subMuted, height: 1.45))
          ]
        ]))
      ]),
    );
  }
}

class _ListSectionHeader extends StatelessWidget {
  const _ListSectionHeader({required this.title, this.action});
  final String title;
  final String? action;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _subInk))),
        if (action != null)
          Text('+  $action',
              style: const TextStyle(
                  color: _subPurple, fontWeight: FontWeight.w800))
      ]));
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items, this.large = false});
  final List<(String, IconData, Color)> items;
  final bool large;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _subLine),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
          children: items
              .map((item) => Container(
                  padding: EdgeInsets.symmetric(vertical: large ? 19 : 13),
                  decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: _subLine))),
                  child: Row(children: [
                    Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: item.$3.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(item.$2, color: item.$3)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Text(item.$1,
                            style: TextStyle(
                                fontSize: large ? 14 : 12,
                                fontWeight: FontWeight.w700,
                                color: _subInk))),
                    const Icon(Icons.chevron_right_rounded, color: _subMuted)
                  ])))
              .toList()),
    );
  }
}
