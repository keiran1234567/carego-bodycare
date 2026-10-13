import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../utils/app_routes.dart';
import '../utils/app_theme.dart';
import '../widgets/info_card.dart';
import '../widgets/responsive_page.dart';
import '../widgets/section_header.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = AppStore.instance.dashboard;
    const menus = [
      ('Kelola User', Icons.people_rounded, AppRoutes.adminUsers),
      ('Kelola Mitra', Icons.storefront_rounded, AppRoutes.adminPartners),
      ('Kelola Pelayan', Icons.badge_rounded, AppRoutes.adminEmployees),
      ('Kelola Layanan', Icons.spa_rounded, AppRoutes.adminServices),
      ('Kelola Booking', Icons.event_available_rounded, AppRoutes.adminBookings),
      ('Kelola Voucher', Icons.confirmation_number_rounded, AppRoutes.adminVouchers),
      ('Kelola Pembayaran', Icons.payments_rounded, AppRoutes.adminPayments),
      ('Laporan', Icons.bar_chart_rounded, AppRoutes.adminReports),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.profile,
              arguments: 'Admin',
            ),
            icon: const Icon(Icons.person_rounded),
          ),
        ],
      ),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .9,
              children: [
                _AdminStat(
                  label: 'Total user',
                  value: '${dashboard['users'] ?? 0}',
                  icon: Icons.people_rounded,
                ),
                _AdminStat(
                  label: 'Total mitra',
                  value: '${dashboard['mitras'] ?? 0}',
                  icon: Icons.storefront_rounded,
                ),
                _AdminStat(
                  label: 'Total pelayan',
                  value: '${dashboard['pelayans'] ?? 0}',
                  icon: Icons.badge_rounded,
                ),
                _AdminStat(
                  label: 'Total booking',
                  value: '${dashboard['bookings'] ?? 0}',
                  icon: Icons.event_available_rounded,
                ),
              ],
            ),
            const SectionHeader(title: 'Menu'),
            ...menus.map(
              (menu) => InkWell(
                onTap: () => Navigator.pushNamed(context, menu.$3),
                borderRadius: BorderRadius.circular(8),
                child: InfoCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.softPurple,
                        foregroundColor: AppColors.purple,
                        child: Icon(menu.$2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          menu.$1,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  const _AdminStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.all(14),
      color: AppColors.softPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.purple),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
