import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import 'app_store.dart';

class UiService {
  const UiService({
    required this.name,
    required this.partner,
    required this.price,
    required this.duration,
    required this.rating,
    required this.image,
    required this.icon,
  });

  final String name;
  final String partner;
  final String price;
  final String duration;
  final double rating;
  final String image;
  final IconData icon;
}

class UiTherapist {
  const UiTherapist({
    required this.name,
    required this.role,
    required this.rating,
    required this.image,
    required this.experience,
  });

  final String name;
  final String role;
  final double rating;
  final String image;
  final String experience;
}

class UiNotification {
  const UiNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.category,
    required this.icon,
    required this.color,
    this.unread = false,
    this.action,
  });

  final String title;
  final String body;
  final String time;
  final String category;
  final IconData icon;
  final Color color;
  final bool unread;
  final String? action;
}

// Local images are presentation fallbacks, while all displayed records and
// values below are built from the backend-backed AppStore.
const uiHeroImage = 'assets/images/home_hero.png';
const uiSalonImage = 'assets/images/salon_interior.png';

List<UiService> get uiServices => AppStore.instance.layanans.map((service) {
      final matches = AppStore.instance.mitras
          .where((partner) => partner.serviceIds.contains(service.id));
      final partner = matches.isEmpty ? '' : matches.first.name;
      return UiService(
        name: service.name,
        partner: partner,
        price: AppFormatters.currency(service.price),
        duration: service.duration,
        rating: matches.isEmpty ? 0 : matches.first.rating,
        image: uiHeroImage,
        icon: service.icon,
      );
    }).toList();

List<UiTherapist> get uiTherapists => AppStore.instance.pelayans
    .map((employee) => UiTherapist(
          name: employee.name,
          role: employee.specialty,
          rating: employee.rating,
          image: uiHeroImage,
          experience: employee.portfolioItems.isEmpty
              ? 'Profil backend'
              : '${employee.portfolioItems.length} portofolio',
        ))
    .toList();

List<UiNotification> get uiNotifications =>
    AppStore.instance.notifications.map((notification) {
      final booking = notification.type.toUpperCase().contains('BOOKING');
      return UiNotification(
        title: notification.title,
        body: notification.message,
        time: notification.createdAt,
        category: notification.type,
        icon: booking
            ? Icons.event_available_rounded
            : Icons.notifications_none_rounded,
        color: booking ? const Color(0xFF6842E8) : const Color(0xFF20B486),
        unread: !notification.read,
      );
    }).toList();
