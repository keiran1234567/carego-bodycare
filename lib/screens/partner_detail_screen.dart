import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../utils/app_routes.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/info_card.dart';
import '../widgets/responsive_page.dart';
import '../widgets/section_header.dart';

class PartnerDetailScreen extends StatelessWidget {
  const PartnerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (partners.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Mitra')),
        body: const Center(
          child: Text('Data mitra belum tersedia dari server.'),
        ),
      );
    }
    final partner = partners.first;
    final partnerServices =
        services.where((service) => partner.serviceIds.contains(service.id));
    final partnerEmployees = employees
        .where((employee) => partner.employeeIds.contains(employee.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Mitra')),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoCard(
              color: AppColors.softPink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.pink,
                    child: Icon(Icons.storefront_rounded, size: 30),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    partner.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rating ${partner.rating} - ${partner.distance}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    partner.address,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: 'Daftar layanan'),
            ...partnerServices.map(
              (service) => InfoCard(
                child: Row(
                  children: [
                    Icon(service.icon, color: AppColors.purple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(service.description),
                        ],
                      ),
                    ),
                    Text(
                      AppFormatters.currency(service.price),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            const SectionHeader(title: 'Pelayan / karyawan'),
            ...partnerEmployees.map(
              (employee) => InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: employee.available
                              ? AppColors.mint
                              : AppColors.softPurple,
                          child: Text(employee.name.characters.first),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${employee.specialty} - Rating ${employee.rating}',
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(
                            employee.available ? 'Tersedia' : 'Tidak tersedia',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Portofolio hasil kerja',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 82,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: employee.portfolio.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, index) => Container(
                          width: 118,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: index.isEven
                                ? AppColors.softPink
                                : AppColors.softPurple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.photo_camera_rounded,
                                color: AppColors.purple,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                employee.portfolio[index],
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.booking),
              child: const Text('Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
