import 'package:flutter/material.dart';

import '../../data/user_ui_dummy_data.dart';
import '../../widgets/user_ui_widgets.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  var selected = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = ['Semua', 'Booking', 'Promo', 'Sistem'];
    final notifications = selected == 0
        ? uiNotifications
        : uiNotifications
            .where((item) =>
                item.category.toLowerCase() == tabs[selected].toLowerCase())
            .toList();
    return UserPage(
      children: [
        const CustomHeader(
            title: 'Notifikasi',
            trailing: Icon(Icons.settings_outlined, color: userPrimary)),
        const SizedBox(height: 18),
        SoftCard(
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showCounts = constraints.maxWidth >= 430;
              return Row(
                children: List.generate(tabs.length, (index) {
                  final active = index == selected;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => selected = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            color:
                                active ? const Color(0xFFF4F0FF) : Colors.white,
                            border: Border.all(
                                color: active ? userPrimary : userLine),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(tabs[index],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: active ? userPrimary : userInk,
                                        fontWeight: FontWeight.w900)),
                              ),
                              if (showCounts) ...[
                                const SizedBox(width: 8),
                                CircleAvatar(
                                    radius: 12,
                                    backgroundColor: active
                                        ? userPrimary
                                        : const Color(0xFFB8BDCF),
                                    child: Text(
                                        '${index == 0 ? uiNotifications.length : uiNotifications.where((item) => item.category.toLowerCase() == tabs[index].toLowerCase()).length}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11))),
                              ],
                            ]),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        const SectionTitle(title: 'Notifikasi dari Server'),
        if (notifications.isEmpty)
          const SoftCard(child: Text('Belum ada notifikasi.'))
        else
          ...notifications.map(
              (notification) => NotificationCard(notification: notification)),
        const SizedBox(height: 18),
        const Text('Notifikasi hanya akan disimpan selama 30 hari.',
            textAlign: TextAlign.center, style: TextStyle(color: userMuted)),
      ],
    );
  }
}
