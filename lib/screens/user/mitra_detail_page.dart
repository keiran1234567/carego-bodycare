import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../data/user_ui_dummy_data.dart';
import '../../utils/app_routes.dart';
import '../../widgets/user_ui_widgets.dart';

class MitraDetailPage extends StatelessWidget {
  const MitraDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    if (store.mitras.isEmpty) {
      return const UserPage(
        children: [
          CustomHeader(title: 'Detail Mitra'),
          SizedBox(height: 40),
          Center(child: Text('Data mitra belum tersedia dari server.')),
        ],
      );
    }
    final partner = store.mitras.first;
    final partnerServices =
        uiServices.where((service) => service.partner == partner.name).toList();
    final partnerTherapists = uiTherapists
        .where((therapist) => store.pelayans.any((employee) =>
            employee.mitraId == partner.id && employee.name == therapist.name))
        .toList();
    return UserPage(
      bottom: BottomActionBar(
        secondaryLabel: 'Chat Mitra',
        primaryLabel: 'Booking Sekarang',
        onSecondary: () => Navigator.pushNamed(context, AppRoutes.chat),
        onPrimary: () =>
            Navigator.pushNamed(context, AppRoutes.userTherapistDetail),
      ),
      children: [
        CustomHeader(
          title: 'Detail Mitra',
          trailing: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.favorite_border_rounded, color: userInk),
              const SizedBox(width: 12),
              GestureDetector(
                  onTap: () {},
                  child: const Icon(Icons.share_outlined, color: userInk)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.asset(uiSalonImage,
                  height: 220, width: double.infinity, fit: BoxFit.cover),
              Positioned(
                left: 18,
                bottom: 18,
                child: Container(
                  width: 130,
                  height: 100,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.spa_outlined, color: userPrimary, size: 42),
                        Text('Glow',
                            style: TextStyle(
                                color: userPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w600)),
                        Text('BEAUTY STUDIO',
                            style: TextStyle(fontSize: 8, color: userMuted))
                      ]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(partner.name,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: userInk)),
        const SizedBox(height: 8),
        Text('Rating ${partner.rating}',
            style: const TextStyle(color: userMuted)),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Badge('Home Service', Icons.home_outlined),
            _Badge('Terverifikasi', Icons.verified_user_outlined),
            _Badge('Berpengalaman', Icons.workspace_premium_outlined),
            _Badge('Harga Terjangkau', Icons.sell_outlined),
          ],
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(
            children: [
              _InfoRow(
                  icon: Icons.location_on_outlined,
                  title: partner.address,
                  subtitle: partner.email),
              const Divider(color: userLine),
              const _InfoRow(
                  icon: Icons.schedule_rounded,
                  title: 'Buka Setiap Hari',
                  subtitle: '08:00 - 22:00'),
            ],
          ),
        ),
        const SectionTitle(title: 'Tentang Mitra'),
        Text(partner.description,
            style: const TextStyle(color: userMuted, height: 1.5)),
        const SizedBox(height: 18),
        const SectionTitle(title: 'Layanan Unggulan', action: 'Lihat Semua'),
        SizedBox(
          height: 184,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: partnerServices.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) => ServiceCard(
                    service: partnerServices[index],
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.userServiceDetail),
                  )),
        ),
        const SizedBox(height: 18),
        const SectionTitle(title: 'Terapis / Pelayan', action: 'Lihat Semua'),
        SizedBox(
          height: 136,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: partnerTherapists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) =>
                  PelayanCard(therapist: partnerTherapists[index])),
        ),
        const SizedBox(height: 18),
        const SectionTitle(title: 'Ulasan Pelanggan', action: 'Lihat Semua'),
        const _ReviewSummary(),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.icon);
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: userPrimary),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: userInk))
      ]));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: userMuted),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, color: userInk)),
          Text(subtitle, style: const TextStyle(color: userMuted))
        ])),
        const Icon(Icons.chevron_right_rounded, color: userMuted)
      ]);
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary();
  @override
  Widget build(BuildContext context) => const SoftCard(
          child: Row(children: [
        SizedBox(
            width: 120,
            child: Column(children: [
              Text('4.8',
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: userInk)),
              Text('★★★★★', style: TextStyle(color: Color(0xFFFFB827))),
              Text('(256 ulasan)',
                  style: TextStyle(color: userMuted, fontSize: 11))
            ])),
        VerticalDivider(),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Amanda Putri',
              style: TextStyle(fontWeight: FontWeight.w900, color: userInk)),
          SizedBox(height: 6),
          Text('★★★★★  5.0', style: TextStyle(color: userPrimary)),
          SizedBox(height: 8),
          Text('Terapisnya ramah, hasilnya memuaskan! Pasti booking lagi.',
              style: TextStyle(color: userMuted, height: 1.4))
        ]))
      ]));
}
