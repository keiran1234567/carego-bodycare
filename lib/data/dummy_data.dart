import 'package:flutter/material.dart';

import '../models/app_models.dart';
import 'app_store.dart';

// Compatibility adapter for older screens. Every value comes from the API-backed
// AppStore; this file no longer contains prototype records.
List<User> get users => AppStore.instance.users;
List<Layanan> get layanan => AppStore.instance.layanans;
List<Layanan> get services => AppStore.instance.layanans;
List<Pelayan> get pelayan => AppStore.instance.pelayans;
List<Pelayan> get employees => AppStore.instance.pelayans;
List<Mitra> get mitra => AppStore.instance.mitras;
List<Mitra> get partners => AppStore.instance.mitras;
List<Booking> get bookings => AppStore.instance.bookings;
List<Pembayaran> get pembayaran => AppStore.instance.payments;
List<Pembayaran> get payments => AppStore.instance.payments;
List<Review> get reviews => AppStore.instance.reviews;
List<Riwayat> get riwayat => AppStore.instance.histories;
List<Riwayat> get histories => AppStore.instance.histories;
List<Portofolio> get portofolios =>
    AppStore.instance.pelayans.expand((item) => item.portfolioItems).toList();
List<Portofolio> get portfolios => portofolios;

List<ServiceCategory> get serviceCategories {
  final categories = <String>{...layanan.map((item) => item.category)};
  return categories
      .map((name) => ServiceCategory(name: name, icon: _categoryIcon(name)))
      .toList();
}

Layanan serviceById(String id) => layanan.firstWhere(
      (item) => item.id == id,
      orElse: () => Layanan(
        id: id,
        name: 'Layanan tidak tersedia',
        category: 'Layanan',
        duration: '-',
        price: 0,
        icon: Icons.miscellaneous_services_rounded,
        description: '',
        active: false,
      ),
    );
Mitra partnerById(String id) => mitra.firstWhere(
      (item) => item.id == id,
      orElse: () => Mitra(
        id: id,
        userId: '',
        name: 'Mitra tidak tersedia',
        email: '',
        phone: '',
        address: '',
        rating: 0,
        distance: '',
        description: '',
        serviceIds: const [],
        employeeIds: const [],
        isOpen: false,
      ),
    );
Pelayan employeeById(String id) => pelayan.firstWhere(
      (item) => item.id == id,
      orElse: () => Pelayan(
        id: id,
        mitraId: '',
        name: 'Pelayan tidak tersedia',
        email: '',
        phone: '',
        specialty: '',
        rating: 0,
        available: false,
        photoUrl: '',
        portfolioItems: const [],
      ),
    );
Pembayaran? paymentById(String id) {
  final matches = pembayaran.where((item) => item.id == id);
  return matches.isEmpty ? null : matches.first;
}

List<Riwayat> historiesByBookingId(String bookingId) =>
    riwayat.where((item) => item.bookingId == bookingId).toList();

IconData _categoryIcon(String value) {
  final category = value.toLowerCase();
  if (category.contains('nail')) return Icons.back_hand_outlined;
  if (category.contains('hair') || category.contains('rambut')) {
    return Icons.content_cut_rounded;
  }
  if (category.contains('spa')) return Icons.spa_outlined;
  return Icons.face_retouching_natural_outlined;
}
