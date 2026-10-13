import 'package:flutter/material.dart';

import '../utils/app_routes.dart';
import '../utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  var index = 0;

  final slides = const [
    _OnboardingData(
      image: 'assets/images/onboarding_professional.png',
      title: 'Perawatan Profesional\nDatang ke Rumah Anda',
      body:
          'Layanan kecantikan dan perawatan\ndari tenaga profesional terpercaya.',
    ),
    _OnboardingData(
      image: 'assets/images/onboarding_booking.png',
      title: 'Booking Mudah\nKapan Saja',
      body: 'Pilih layanan, atur jadwal,\ndan nikmati perawatan tanpa ribet.',
    ),
    _OnboardingData(
      image: 'assets/images/onboarding_trusted.png',
      title: 'Terpercaya &\nBerkualitas',
      body: 'Kami memastikan pelayanan terbaik\nuntuk kepuasan Anda.',
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFF),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _OnboardingWaveBackground()),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: controller,
                      onPageChanged: (value) => setState(() => index = value),
                      itemCount: slides.length,
                      itemBuilder: (_, slideIndex) =>
                          _OnboardingSlide(data: slides[slideIndex]),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (dotIndex) {
                      final active = dotIndex == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: active ? 18 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: active ? AppColors.purple : AppColors.line,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () {
                        if (index == slides.length - 1) {
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.roleSelection);
                        } else {
                          controller.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        index == slides.length - 1 ? 'Mulai' : 'Selanjutnya',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
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

class _OnboardingData {
  const _OnboardingData({
    required this.image,
    required this.title,
    required this.body,
  });

  final String image;
  final String title;
  final String body;
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxHeight < 560;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            data.image,
            width: compact ? 170 : 215,
            height: compact ? 150 : 185,
            fit: BoxFit.contain,
          ),
          SizedBox(height: compact ? 22 : 36),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.55,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    });
  }
}

class _OnboardingWaveBackground extends StatelessWidget {
  const _OnboardingWaveBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _OnboardingWavePainter());
  }
}

class _OnboardingWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.softPurple.withValues(alpha: .55);
    final path = Path()
      ..moveTo(0, size.height * .9)
      ..cubicTo(size.width * .28, size.height * .82, size.width * .44,
          size.height, size.width * .66, size.height * .92)
      ..cubicTo(size.width * .8, size.height * .87, size.width * .9,
          size.height * .83, size.width, size.height * .82)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
