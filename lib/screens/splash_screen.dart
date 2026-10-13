import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/app_models.dart';
import '../utils/app_routes.dart';
import '../utils/app_theme.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? error;
  var retrying = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future.wait([
      AppStore.instance.initialize(),
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);
    if (!mounted) return;
    _continueAfterInitialization();
  }

  void _continueAfterInitialization() {
    final store = AppStore.instance;
    if (store.online && store.isAuthenticated && store.currentUser != null) {
      final route = switch (store.currentUser!.role) {
        AppRole.user => AppRoutes.userDashboard,
        AppRole.mitra => store.currentMitra?.isApproved == true
            ? AppRoutes.partnerDashboard
            : AppRoutes.registrationStatus,
        AppRole.pelayan => AppRoutes.employeeDashboard,
        AppRole.admin => AppRoutes.adminDashboard,
      };
      Navigator.pushReplacementNamed(context, route);
      return;
    }

    if (!store.online && store.error != null) {
      setState(() => error = store.error);
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
  }

  Future<void> _retry() async {
    setState(() {
      retrying = true;
      error = null;
    });
    await AppStore.instance.initialize(force: true);
    if (!mounted) return;
    setState(() => retrying = false);
    _continueAfterInitialization();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFFFFBFF), Color(0xFFF4EDFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: _SplashWaveBackground()),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(size: 255),
                      const SizedBox(height: 28),
                      if (error == null || retrying)
                        const SizedBox(height: 28)
                      else ...[
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba Lagi'),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.onboarding,
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Buka Aplikasi'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashWaveBackground extends StatelessWidget {
  const _SplashWaveBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SplashWavePainter());
  }
}

class _SplashWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pink = Paint()..color = AppColors.softPink.withValues(alpha: .7);
    final purple = Paint()..color = AppColors.softPurple.withValues(alpha: .9);

    final pinkPath = Path()
      ..moveTo(0, size.height * .82)
      ..cubicTo(size.width * .24, size.height * .76, size.width * .42,
          size.height * .98, size.width * .68, size.height * .86)
      ..cubicTo(size.width * .82, size.height * .78, size.width * .92,
          size.height * .75, size.width, size.height * .75)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(pinkPath, pink);

    final purplePath = Path()
      ..moveTo(0, size.height * .9)
      ..cubicTo(size.width * .18, size.height * .84, size.width * .38,
          size.height * .92, size.width * .55, size.height * .96)
      ..cubicTo(size.width * .74, size.height, size.width * .88,
          size.height * .89, size.width, size.height * .86)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(purplePath, purple);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
