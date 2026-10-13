import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/app_models.dart';
import '../utils/app_routes.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/bottom_navs.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildRoleBlueTheme(
        Theme.of(context),
        primary: const Color(0xFF1459C5),
        secondary: const Color(0xFF3E79F8),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        bottomNavigationBar: const UserBottomNav(currentIndex: 0),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                children: [
                  const _HomeHeader(),
                  const SizedBox(height: 18),
                  const _SearchBar(),
                  const SizedBox(height: 18),
                  const _HeroBanner(),
                  const SizedBox(height: 9),
                  const _PageDots(),
                  const SizedBox(height: 8),
                  const _HomeSectionHeader(
                      title: 'Kategori Layanan', showAction: false),
                  const SizedBox(height: 12),
                  const _CategoryList(),
                  const SizedBox(height: 20),
                  const _HomeSectionHeader(title: 'Layanan Populer'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 226,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _visibleServices.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, index) =>
                          _ServiceCard(service: _visibleServices[index]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _HomeSectionHeader(title: 'Mitra Terdekat'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 190,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppStore.instance.mitras.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, index) => _PartnerCard(index: index),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _PromoBanner(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${AppStore.instance.currentUser?.name ?? 'Keiran'}',
                style: const TextStyle(
                  color: Color(0xFF11131A),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Sehat & percaya diri setiap hari',
                style: TextStyle(color: Color(0xFF7B7F89), fontSize: 14),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.userNotifications),
              icon: const Icon(Icons.notifications_none_rounded, size: 28),
            ),
            Positioned(
              right: 9,
              top: 7,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          borderRadius: BorderRadius.circular(30),
          child: const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFE7EEFF),
            child:
                Icon(Icons.person_rounded, color: Color(0xFF1459B8), size: 30),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E8EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1F2D4D),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(width: 16),
          Icon(Icons.search_rounded, color: Color(0xFF727782)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cari layanan body care...',
              style: TextStyle(color: Color(0xFF8A8E98), fontSize: 14),
            ),
          ),
          Icon(Icons.tune_rounded, color: Color(0xFF555B66)),
          SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 400;
    return SizedBox(
      height: compact ? 220 : 166,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/home_hero.png', fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF1F8FF),
                    Color(0xE8EAF6FF),
                    Color(0x00EAF6FF),
                  ],
                  stops: [0, .43, .72],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width:
                      MediaQuery.sizeOf(context).width * (compact ? .58 : .44),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Perawatan privat\ndatang ke rumah',
                        style: TextStyle(
                          color: Color(0xFF101621),
                          fontSize: 18,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Booking mudah, pelayanan terbaik langsung di rumah Anda',
                        maxLines: 2,
                        style: TextStyle(fontSize: 10.5, height: 1.3),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 34,
                        child: FilledButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.booking),
                          iconAlignment: IconAlignment.end,
                          icon:
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Booking Sekarang',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1459C5),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
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
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(active: true),
        _Dot(),
        _Dot(),
        _Dot(),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 8 : 7,
      height: active ? 8 : 7,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1465D4) : const Color(0xFFD8E1EF),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({required this.title, this.showAction = true});

  final String title;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF151820),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (showAction)
          TextButton.icon(
            onPressed: () {},
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.chevron_right_rounded, size: 19),
            label: const Text('Lihat semua'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1459B8),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList();

  static const categories = [
    (
      name: 'Cukur Rambut',
      image: 'assets/images/category_haircut.png',
    ),
    (
      name: 'Salon',
      image: 'assets/images/category_salon.png',
    ),
    (
      name: 'Nail Art',
      image: 'assets/images/category_nail_art.png',
    ),
    (
      name: 'Facial',
      image: 'assets/images/category_facial.png',
    ),
    (
      name: 'Make Up',
      image: 'assets/images/category_makeup.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 13),
        itemBuilder: (_, index) {
          final category = categories[index];
          return InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.userCategoryTherapists,
              arguments: category.name,
            ),
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      category.image,
                      width: 62,
                      height: 62,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final Layanan service;

  static const images = [
    'assets/images/service_hair_treatment.png',
    'assets/images/service_premium_haircut.png',
    'assets/images/service_nail_care.png',
    'assets/images/service_facial_glow.png',
  ];

  @override
  Widget build(BuildContext context) {
    final index = _visibleServices.indexWhere((item) => item.id == service.id);
    final image = index >= 0 && index < images.length
        ? images[index]
        : 'assets/images/salon_interior.png';
    return Container(
      width: 154,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EBF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1A2A49),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 80,
                width: double.infinity,
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        AppStore.instance.toggleServiceFavorite(service.id),
                    icon: Icon(
                      AppStore.instance.isServiceFavorite(service.id)
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 16,
                      color: const Color(0xFF2284E8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    AppFormatters.currency(service.price),
                    style: const TextStyle(
                      color: Color(0xFF1459B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 12, color: Color(0xFF747985)),
                      const SizedBox(width: 3),
                      Expanded(
                          child: Text(service.duration,
                              style: const TextStyle(fontSize: 9))),
                      const Icon(Icons.star_rounded,
                          size: 13, color: Color(0xFFFFC21C)),
                      const Text('4.8', style: TextStyle(fontSize: 9)),
                    ],
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.booking,
                        arguments: service.id,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1459B8),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: Color(0xFF92B9E9)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7)),
                      ),
                      child: const Text('Pilih',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Layanan> get _visibleServices => AppStore.instance.layanans
    .where((service) => !_isRemovedCareService(service.name, service.category))
    .toList();

bool _isRemovedCareService(String name, String category) {
  final value = '$name $category'.toLowerCase();
  return value.contains('spa') ||
      value.contains('massage') ||
      value.contains('pijat');
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final partner = AppStore.instance.mitras[index];
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.userMitraDetail),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 205,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EBF1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  'assets/images/salon_interior.png',
                  height: 72,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  left: 9,
                  bottom: 7,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF13528F),
                    child: Text(
                      partner.name
                          .split(' ')
                          .take(2)
                          .map((word) => word.characters.first)
                          .join(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          height: 1.15,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      partner.address.split(',').last.trim(),
                      style: const TextStyle(
                          fontSize: 9, color: Color(0xFF777C86)),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFC21C), size: 14),
                        Text(' ${partner.rating}',
                            style: const TextStyle(fontSize: 9)),
                        const Spacer(),
                        Text('${partner.employeeIds.length + 7} Pelayan',
                            style: const TextStyle(fontSize: 9)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 25,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.userMitraDetail),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1459B8),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: Color(0xFFB0CBEA)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Lihat Detail',
                            style: TextStyle(fontSize: 10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF88BEFF), Color(0xFF72E1D1)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded,
              size: 38, color: Color(0xFFFFE75A)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Dapatkan diskon spesial\nuntuk pengguna baru!',
              style: TextStyle(
                  color: Color(0xFF104D99),
                  fontSize: 11,
                  fontWeight: FontWeight.w900),
            ),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.promoVoucher),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF164F8E),
              minimumSize: const Size(82, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Cek Promo', style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
