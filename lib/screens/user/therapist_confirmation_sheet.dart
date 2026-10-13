import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../utils/app_routes.dart';
import '../../utils/formatters.dart';

const _confirmPurple = Color(0xFF6548EE);
const _confirmInk = Color(0xFF151529);
const _confirmMuted = Color(0xFF74758A);
const _confirmLine = Color(0xFFE8E6F2);

Future<void> showTherapistConfirmationSheet(
  BuildContext context, {
  required Pelayan employee,
  required Layanan service,
  String distance = '2.4 km dari lokasi Anda',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _TherapistConfirmationSheet(
      employee: employee,
      service: service,
      distance: distance,
      onChoose: () {
        Navigator.pop(sheetContext);
        Navigator.pushNamed(context, AppRoutes.booking, arguments: {
          'serviceId': service.id,
          'employeeId': employee.id,
        });
      },
    ),
  );
}

class _TherapistConfirmationSheet extends StatelessWidget {
  const _TherapistConfirmationSheet({
    required this.employee,
    required this.service,
    required this.distance,
    required this.onChoose,
  });

  final Pelayan employee;
  final Layanan service;
  final String distance;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .9,
      minChildSize: .48,
      maxChildSize: .94,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          children: [
            Center(
              child: Container(
                width: 56,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7D1F6),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Konfirmasi Pelayan',
                    style: TextStyle(
                      color: _confirmInk,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _ConfirmPersonImage(url: employee.photoUrl),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              employee.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _confirmInk,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Icon(Icons.verified_rounded,
                              color: _confirmPurple, size: 18),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(employee.specialty,
                          style: const TextStyle(
                              color: _confirmMuted, fontSize: 12)),
                      const SizedBox(height: 10),
                      Text(
                        '⭐ ${employee.rating.toStringAsFixed(1)} (${employee.reviewItems.length})  •  ${employee.experienceYears} Tahun Pengalaman',
                        style:
                            const TextStyle(color: _confirmMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _AboutTherapist(employee: employee),
            const SizedBox(height: 14),
            _RatingReviewSummary(employee: employee),
            const SizedBox(height: 14),
            if (employee.portfolioItems.isNotEmpty) ...[
              _PortfolioPreview(items: employee.portfolioItems),
              const SizedBox(height: 18),
            ],
            _ConfirmInfoTile(
              icon: Icons.content_cut_rounded,
              title: 'Layanan',
              value: service.name,
            ),
            _ConfirmInfoTile(
              icon: Icons.sell_outlined,
              title: 'Harga',
              value: AppFormatters.currency(service.price),
            ),
            _ConfirmInfoTile(
              icon: Icons.location_on_outlined,
              title: 'Jarak',
              value: distance,
            ),
            _ConfirmInfoTile(
              icon: Icons.schedule_outlined,
              title: 'Durasi',
              value: service.duration,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _confirmPurple,
                      side: const BorderSide(color: _confirmPurple, width: 1.3),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                    child: const Text('Batalkan',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: onChoose,
                    style: FilledButton.styleFrom(
                      backgroundColor: _confirmPurple,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                    child: const Text('Pilih Pelayan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: _confirmMuted, size: 14),
                SizedBox(width: 6),
                Text('Data Anda aman dan tidak dibagikan ke pihak lain.',
                    style: TextStyle(color: _confirmMuted, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutTherapist extends StatelessWidget {
  const _AboutTherapist({required this.employee});

  final Pelayan employee;

  @override
  Widget build(BuildContext context) => _ConfirmSection(
        title: 'Tentang Pelayan',
        child: Text(
          employee.bio.isEmpty
              ? 'Pelayan profesional CareGo yang siap memberikan layanan terbaik sesuai kebutuhan Anda.'
              : employee.bio,
          style:
              const TextStyle(color: _confirmMuted, height: 1.45, fontSize: 12),
        ),
      );
}

class _RatingReviewSummary extends StatelessWidget {
  const _RatingReviewSummary({required this.employee});

  final Pelayan employee;

  @override
  Widget build(BuildContext context) {
    final reviews = employee.reviewItems;
    return _ConfirmSection(
      title: 'Rating & Ulasan',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: _confirmInk,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text('★★★★★',
                        style:
                            TextStyle(color: Color(0xFFFFB316), fontSize: 13)),
                    Text('(${reviews.length} ulasan)',
                        style: const TextStyle(
                            color: _confirmMuted, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final star = 5 - index;
                    final count = reviews
                        .where((review) => review.rating.round() == star)
                        .length;
                    final ratio = reviews.isEmpty
                        ? (star == 5 ? .75 : .08)
                        : count / reviews.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 16,
                              child: Text('$star',
                                  style: const TextStyle(fontSize: 10))),
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFB316), size: 13),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: ratio.clamp(0, 1),
                                minHeight: 5,
                                backgroundColor: const Color(0xFFEFEAFD),
                                valueColor: const AlwaysStoppedAnimation(
                                    _confirmPurple),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 22,
                            child: Text(
                              reviews.isEmpty && star == 5 ? '112' : '$count',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  color: _confirmMuted, fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          if (reviews.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...reviews.take(2).map((review) => _MiniReview(review: review)),
          ] else ...[
            const SizedBox(height: 12),
            const _StaticMiniReview(
              name: 'Pelanggan CareGo',
              comment: 'Hasil kerja rapi, ramah, dan sesuai request.',
            ),
            const _StaticMiniReview(
              name: 'Pelanggan CareGo',
              comment: 'Pelayan profesional, nyaman, akan langganan terus.',
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniReview extends StatelessWidget {
  const _MiniReview({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFECE8FF),
              child: Text(
                review.userName.isEmpty ? 'U' : review.userName[0],
                style: const TextStyle(
                    color: _confirmPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.userName.isEmpty
                        ? 'Pelanggan CareGo'
                        : review.userName,
                    style: const TextStyle(
                        color: _confirmInk,
                        fontSize: 11,
                        fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    review.comment.isEmpty
                        ? 'Terima kasih atas pelayanannya.'
                        : review.comment,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _confirmMuted, fontSize: 10, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StaticMiniReview extends StatelessWidget {
  const _StaticMiniReview({required this.name, required this.comment});

  final String name;
  final String comment;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFFECE8FF),
              child:
                  Icon(Icons.person_rounded, color: _confirmPurple, size: 16),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: _confirmInk,
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                  Text(comment,
                      style: const TextStyle(
                          color: _confirmMuted, fontSize: 10, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ConfirmSection extends StatelessWidget {
  const _ConfirmSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _confirmLine),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: _confirmInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            child,
          ],
        ),
      );
}

class _PortfolioPreview extends StatelessWidget {
  const _PortfolioPreview({required this.items});

  final List<Portofolio> items;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Portofolio Hasil',
                  style: TextStyle(
                    color: _confirmInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.photo_library_outlined,
                  color: _confirmPurple, size: 19),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                final item = items[index];
                return SizedBox(
                  width: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFECE8FF),
                            child: const Icon(Icons.photo_outlined,
                                color: _confirmPurple),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Color(0xAA111122)],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(9, 18, 9, 8),
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
}

class _ConfirmInfoTile extends StatelessWidget {
  const _ConfirmInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _confirmLine),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF0ECFF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: _confirmPurple),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: _confirmInk,
                          fontWeight: FontWeight.w900,
                          fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(value,
                      style:
                          const TextStyle(color: _confirmMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ConfirmPersonImage extends StatelessWidget {
  const _ConfirmPersonImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        width: 112,
        height: 112,
        color: const Color(0xFFECE8FF),
        child:
            const Icon(Icons.person_rounded, size: 58, color: _confirmPurple),
      );
    }
    return Image.network(
      url,
      width: 112,
      height: 112,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 112,
        height: 112,
        color: const Color(0xFFECE8FF),
        child:
            const Icon(Icons.person_rounded, size: 58, color: _confirmPurple),
      ),
    );
  }
}
