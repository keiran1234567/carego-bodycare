import 'package:flutter/material.dart';

import '../data/user_ui_dummy_data.dart';
import '../utils/app_theme.dart';

const userPrimary = Color(0xFF225CD8);
const userInk = Color(0xFF10163A);
const userMuted = Color(0xFF69708F);
const userLine = Color(0xFFE6E8F1);
const userBg = Color(0xFFF4F8FF);

class CustomHeader extends StatelessWidget {
  const CustomHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final edgeWidth = trailing == null ? 48.0 : 72.0;
    return Row(
      children: [
        SizedBox(
          width: edgeWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: userInk),
            ),
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: userInk,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(width: edgeWidth, child: trailing),
      ],
    );
  }
}

class UserPage extends StatelessWidget {
  const UserPage({super.key, required this.children, this.bottom});

  final List<Widget> children;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildRoleBlueTheme(
        Theme.of(context),
        primary: userPrimary,
        secondary: const Color(0xFF4F76FF),
      ),
      child: Scaffold(
        backgroundColor: userBg,
        bottomNavigationBar: bottom,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding:
                    EdgeInsets.fromLTRB(18, 14, 18, bottom == null ? 26 : 120),
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.margin});

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 14),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: userLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0810163A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900, color: userInk),
            ),
          ),
          if (action != null)
            Text(
              action!,
              style: const TextStyle(
                  color: userPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    this.width = 168,
    this.onTap,
  });

  final UiService service;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: userLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(service.image,
                height: 92, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: userInk)),
                  const SizedBox(height: 5),
                  Text(service.price,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: userInk)),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFB827), size: 16),
                      Flexible(
                        child: Text(' ${service.rating}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: userMuted)),
                      ),
                      const Spacer(),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(service.duration,
                              style: const TextStyle(
                                  fontSize: 11, color: userMuted)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MitraCard extends StatelessWidget {
  const MitraCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(uiSalonImage,
                  width: 88, height: 72, fit: BoxFit.cover)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Glow Beauty Home Service',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, color: userInk)),
                SizedBox(height: 6),
                Text('Rating 4.8 - 256 ulasan - 2.4 km',
                    style: TextStyle(fontSize: 12, color: userMuted)),
                SizedBox(height: 4),
                Text('Jl. Kemang Raya No. 15, Jakarta Selatan',
                    style: TextStyle(fontSize: 12, color: userMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PelayanCard extends StatelessWidget {
  const PelayanCard({super.key, required this.therapist, this.width = 112});

  final UiTherapist therapist;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 132,
      child: Column(
        children: [
          CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFF0EDFF),
              backgroundImage: AssetImage(therapist.image)),
          const SizedBox(height: 8),
          Text(therapist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: userInk)),
          const SizedBox(height: 3),
          Text('Rating ${therapist.rating}',
              style: const TextStyle(fontSize: 12, color: userMuted)),
        ],
      ),
    );
  }
}

class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.active = true,
    this.last = false,
    this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final bool last;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final color = active ? userPrimary : const Color(0xFFADB2C3);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
                radius: 24,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white)),
            if (!last)
              Container(
                  width: 2,
                  height: child == null ? 54 : 176,
                  color: color.withValues(alpha: .45)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: active ? userPrimary : userMuted,
                        fontSize: 15)),
                const SizedBox(height: 5),
                Text(subtitle,
                    style: const TextStyle(color: userMuted, height: 1.35)),
                if (child != null) ...[const SizedBox(height: 12), child!],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard(
      {super.key,
      required this.title,
      required this.icon,
      required this.color});

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color)),
          const SizedBox(width: 14),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: userInk))),
          const Icon(Icons.chevron_right_rounded, color: userMuted),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key, required this.notification});

  final UiNotification notification;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: notification.color.withValues(alpha: .12),
            child: Icon(notification.icon, color: notification.color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: userInk)),
                const SizedBox(height: 6),
                Text(notification.body,
                    style: const TextStyle(color: userInk, height: 1.45)),
                if (notification.action != null) ...[
                  const SizedBox(height: 8),
                  Text('${notification.action!}  ->',
                      style: const TextStyle(
                          color: userPrimary, fontWeight: FontWeight.w900)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(notification.time, style: const TextStyle(color: userMuted)),
              const SizedBox(height: 22),
              if (notification.unread)
                const CircleAvatar(radius: 6, backgroundColor: userPrimary),
            ],
          ),
        ],
      ),
    );
  }
}

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryIcon,
    this.secondaryIcon,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData? primaryIcon;
  final IconData? secondaryIcon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1010163A),
            blurRadius: 18,
            offset: Offset(0, -6),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: Row(
                  children: [
                    if (secondaryLabel != null) ...[
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: onSecondary,
                            icon: Icon(secondaryIcon ??
                                Icons.chat_bubble_outline_rounded),
                            label: FittedBox(child: Text(secondaryLabel!)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: userPrimary,
                              side: const BorderSide(color: userPrimary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: secondaryLabel == null ? 1 : 2,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6339E3), Color(0xFF4424C7)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FilledButton.icon(
                          onPressed: onPrimary,
                          iconAlignment: IconAlignment.end,
                          icon:
                              Icon(primaryIcon ?? Icons.arrow_forward_rounded),
                          label: FittedBox(child: Text(primaryLabel)),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
