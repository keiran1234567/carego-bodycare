import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../widgets/responsive_page.dart';

class RatingReviewScreen extends StatefulWidget {
  const RatingReviewScreen({super.key});

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  var rating = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rating & Review')),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bagaimana pengalamanmu?',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rating dan ulasan membantu mitra menjaga kualitas layanan.',
            ),
            const SizedBox(height: 26),
            Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(5, (index) {
                final active = index < rating;
                return IconButton(
                  onPressed: () => setState(() => rating = index + 1),
                  iconSize: 42,
                  color: active ? AppColors.pink : AppColors.line,
                  icon: const Icon(Icons.star_rounded),
                );
              }),
            ),
            const SizedBox(height: 20),
            const TextField(
              minLines: 5,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: 'Input ulasan',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.rate_review_rounded),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kirim Review'),
            ),
          ],
        ),
      ),
    );
  }
}
