import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/api_client.dart';
import '../../data/app_store.dart';
import '../../data/dummy_data.dart';
import '../../models/app_models.dart';
import '../../widgets/user_ui_widgets.dart';

class UserReviewPage extends StatefulWidget {
  const UserReviewPage({super.key});

  @override
  State<UserReviewPage> createState() => _UserReviewPageState();
}

class _UserReviewPageState extends State<UserReviewPage> {
  final controller = TextEditingController();
  final photos = <String>[];
  var rating = 5;
  var submitting = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = AppStore.instance.bookings
        .where((booking) => booking.status == 'Selesai')
        .toList();
    if (completed.isEmpty) {
      return const UserPage(
        children: [
          CustomHeader(title: 'Rating & Review'),
          SizedBox(height: 32),
          SoftCard(child: Text('Belum ada booking selesai untuk direview.')),
        ],
      );
    }

    final booking = completed.first;
    final service = serviceById(booking.serviceId);
    final partner = partnerById(booking.partnerId);
    final employee = employeeById(booking.employeeId);

    return UserPage(
      children: [
        const CustomHeader(title: 'Rating & Review'),
        const SizedBox(height: 18),
        _BookingReviewCard(
          booking: booking,
          service: service,
          partner: partner,
          employee: employee,
        ),
        _ReviewForm(
          rating: rating,
          review: controller,
          photos: photos,
          submitting: submitting,
          onRating: (value) => setState(() => rating = value),
          onChanged: () => setState(() {}),
          onAddPhoto: _addPhoto,
          onRemovePhoto: (index) => setState(() => photos.removeAt(index)),
          onSubmit: () => _submit(booking.id),
        ),
        const SectionTitle(title: 'Review Sebelumnya'),
        if (AppStore.instance.reviews.isEmpty)
          const SoftCard(child: Text('Belum ada review.'))
        else
          SoftCard(
            child: Column(
              children: AppStore.instance.reviews
                  .map((review) => _PreviousReview(review: review))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _addPhoto() async {
    if (photos.length >= 3) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1200,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      photos.add('data:image/jpeg;base64,${base64Encode(bytes)}');
    });
  }

  Future<void> _submit(String bookingId) async {
    setState(() => submitting = true);
    try {
      await AppStore.instance.submitReview(
        bookingId,
        rating,
        controller.text.trim(),
        mitraRating: rating,
        pelayanRating: rating,
        photoUrls: photos,
      );
      await AppStore.instance.refreshInteractions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review berhasil dikirim.')),
      );
      setState(() {
        controller.clear();
        photos.clear();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }
}

class _BookingReviewCard extends StatelessWidget {
  const _BookingReviewCard({
    required this.booking,
    required this.service,
    required this.partner,
    required this.employee,
  });

  final Booking booking;
  final Layanan service;
  final Mitra partner;
  final Pelayan employee;

  @override
  Widget build(BuildContext context) => SoftCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                _serviceImage(service),
                width: 92,
                height: 92,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: userInk,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6FAEF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                color: Color(0xFF18A65D), size: 16),
                            SizedBox(width: 5),
                            Text('Selesai',
                                style: TextStyle(
                                    color: Color(0xFF18A65D),
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(partner.name, style: const TextStyle(color: userMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    children: [
                      _Meta(
                          icon: Icons.calendar_today_outlined,
                          text: booking.date),
                      _Meta(icon: Icons.schedule_outlined, text: booking.time),
                      const _Meta(
                          icon: Icons.home_outlined, text: 'Home Service'),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 17, color: userMuted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text('Terapis: ${employee.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: userMuted)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ReviewForm extends StatelessWidget {
  const _ReviewForm({
    required this.rating,
    required this.review,
    required this.photos,
    required this.submitting,
    required this.onRating,
    required this.onChanged,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onSubmit,
  });

  final int rating;
  final TextEditingController review;
  final List<String> photos;
  final bool submitting;
  final ValueChanged<int> onRating;
  final VoidCallback onChanged;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star_rounded, color: userPrimary, size: 34),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bagaimana pengalaman Anda?',
                          style: TextStyle(
                              color: userInk,
                              fontSize: 17,
                              fontWeight: FontWeight.w900)),
                      SizedBox(height: 3),
                      Text(
                          'Penilaian Anda sangat berarti untuk kami dan terapis.',
                          style: TextStyle(color: userMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text('Berikan Rating',
                style: TextStyle(color: userInk, fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            Row(
              children: [
                ...List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () => onRating(index + 1),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFFFB316),
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rating.toStringAsFixed(1),
                        style: const TextStyle(
                            color: userInk,
                            fontSize: 25,
                            fontWeight: FontWeight.w900)),
                    Text(_ratingText(rating),
                        style: const TextStyle(
                            color: userPrimary, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Tulis Review (Opsional)',
                style: TextStyle(color: userInk, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            TextField(
              controller: review,
              minLines: 4,
              maxLines: 6,
              maxLength: 300,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                hintText:
                    'Pelayanannya sangat memuaskan! Terapisnya ramah dan profesional...',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${review.text.length} / 300',
                  style: const TextStyle(color: userMuted, fontSize: 12)),
            ),
            const SizedBox(height: 14),
            const Text('Tambahkan Foto (Opsional)',
                style: TextStyle(color: userInk, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ...List.generate(
                  photos.length,
                  (index) => _PickedPhoto(
                    dataUrl: photos[index],
                    onRemove: () => onRemovePhoto(index),
                  ),
                ),
                if (photos.length < 3) _AddPhotoButton(onTap: onAddPhoto),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: submitting ? null : onSubmit,
                child: Text(submitting ? 'Mengirim...' : 'Kirim Review',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      );
}

class _PickedPhoto extends StatelessWidget {
  const _PickedPhoto({required this.dataUrl, required this.onRemove});

  final String dataUrl;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(dataUrl.split(',').last);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(bytes, width: 92, height: 92, fit: BoxFit.cover),
        ),
        Positioned(
          right: -7,
          top: -7,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 8)],
              ),
              child: const Icon(Icons.close_rounded, size: 17, color: userInk),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: userPrimary, style: BorderStyle.solid),
            color: const Color(0xFFFAF8FF),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_camera_outlined, color: userPrimary, size: 31),
              SizedBox(height: 7),
              Text('Tambah Foto',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: userPrimary, fontSize: 12)),
            ],
          ),
        ),
      );
}

class _PreviousReview extends StatelessWidget {
  const _PreviousReview({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFECE8FF),
              child: Text(review.userName.isEmpty ? 'U' : review.userName[0],
                  style: const TextStyle(
                      color: userPrimary, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.userName.isEmpty
                              ? 'Pelanggan CareGo'
                              : review.userName,
                          style: const TextStyle(
                              color: userInk, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Icon(Icons.more_vert_rounded, color: userMuted),
                    ],
                  ),
                  Row(
                    children: [
                      Text('★' * review.rating.round(),
                          style: const TextStyle(color: Color(0xFFFFB316))),
                      const SizedBox(width: 8),
                      Text(review.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: userInk, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    review.comment.isEmpty
                        ? 'Terima kasih atas reviewnya.'
                        : review.comment,
                    style: const TextStyle(color: userMuted, height: 1.35),
                  ),
                  if (review.photoUrls.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 58,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: review.photoUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, index) =>
                            _ReviewPhoto(url: review.photoUrls[index]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _ReviewPhoto extends StatelessWidget {
  const _ReviewPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final child = url.startsWith('data:image')
        ? Image.memory(base64Decode(url.split(',').last), fit: BoxFit.cover)
        : Image.network(url, fit: BoxFit.cover);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(width: 58, height: 58, child: child),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: userMuted),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: userMuted, fontSize: 12)),
        ],
      );
}

String _ratingText(int rating) => switch (rating) {
      5 => 'Sangat Puas',
      4 => 'Puas',
      3 => 'Cukup',
      2 => 'Kurang',
      _ => 'Tidak Puas',
    };

String _serviceImage(Layanan service) {
  final value = '${service.name} ${service.category}'.toLowerCase();
  if (value.contains('nail')) return 'assets/images/service_nail_care.png';
  if (value.contains('cukur') || value.contains('barber')) {
    return 'assets/images/service_premium_haircut.png';
  }
  if (value.contains('hair') || value.contains('salon')) {
    return 'assets/images/service_hair_treatment.png';
  }
  return 'assets/images/service_facial_glow.png';
}
