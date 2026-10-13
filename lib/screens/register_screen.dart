import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/app_store.dart';
import '../models/app_models.dart';
import '../utils/app_routes.dart';

const _registerPurple = Color(0xFF663CE2);
const _registerPurpleDark = Color(0xFF4E2ED0);
const _registerInk = Color(0xFF11173F);
const _registerMuted = Color(0xFF73799A);
const _registerLine = Color(0xFFE6E2F6);
const _registerSurface = Color(0xFFFFFBFF);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  AppRole role = AppRole.user;
  var roleLoaded = false;
  var agreed = false;
  var obscurePassword = true;
  var obscureConfirmation = true;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmationController = TextEditingController();
  var submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!roleLoaded) {
      role = ModalRoute.of(context)?.settings.arguments as AppRole? ??
          AppRole.user;
      roleLoaded = true;
    }
  }

  Future<void> _register() async {
    if (!agreed || passwordController.text != confirmationController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Periksa persetujuan dan konfirmasi password.'),
      ));
      return;
    }
    setState(() => submitting = true);
    try {
      await AppStore.instance.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
        role: role,
      );
      if (!mounted) return;
      final route = switch (role) {
        AppRole.user => AppRoutes.userDashboard,
        AppRole.mitra => AppRoutes.partnerDashboard,
        AppRole.pelayan => AppRoutes.employeeDashboard,
        AppRole.admin => AppRoutes.adminDashboard,
      };
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _registerSurface,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _RegisterWaveBackground()),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: _registerInk, size: 20),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const _RegisterHero(),
                    const SizedBox(height: 26),
                    _RegisterField(
                      icon: Icons.person_outline_rounded,
                      hint: 'Nama Lengkap',
                      controller: nameController,
                    ),
                    const SizedBox(height: 10),
                    _RegisterField(
                      icon: Icons.mail_outline_rounded,
                      hint: 'Email',
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    _RegisterField(
                      icon: Icons.phone_android_rounded,
                      hint: 'Nomor HP',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    _RegisterField(
                      icon: Icons.lock_outline_rounded,
                      hint: 'Kata Sandi',
                      controller: passwordController,
                      obscure: obscurePassword,
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => obscurePassword = !obscurePassword),
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _registerMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RegisterField(
                      icon: Icons.lock_outline_rounded,
                      hint: 'Konfirmasi Kata Sandi',
                      controller: confirmationController,
                      obscure: obscureConfirmation,
                      suffix: IconButton(
                        onPressed: () => setState(
                            () => obscureConfirmation = !obscureConfirmation),
                        icon: Icon(
                          obscureConfirmation
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _registerMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: agreed,
                            onChanged: (value) =>
                                setState(() => agreed = value ?? false),
                            activeColor: _registerPurple,
                            side: const BorderSide(color: _registerLine),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: _registerMuted),
                              children: [
                                TextSpan(text: 'Saya setuju dengan '),
                                TextSpan(
                                  text: 'Syarat & Ketentuan',
                                  style: TextStyle(
                                      color: _registerPurple,
                                      fontWeight: FontWeight.w800),
                                ),
                                TextSpan(text: '\ndan '),
                                TextSpan(
                                  text: 'Kebijakan Privasi',
                                  style: TextStyle(
                                      color: _registerPurple,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _RegisterButton(
                      label: submitting ? 'Mendaftarkan...' : 'Daftar',
                      onPressed: submitting ? null : _register,
                    ),
                    const SizedBox(height: 30),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text('Sudah punya akun? ',
                            style: TextStyle(
                                color: _registerMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                              context, AppRoutes.login),
                          child: const Text(
                            'Masuk di sini',
                            style: TextStyle(
                              color: _registerPurple,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
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

class _RegisterHero extends StatelessWidget {
  const _RegisterHero();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat Akun Baru',
                style: TextStyle(
                  fontSize: 22,
                  color: _registerInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Daftar untuk menikmati berbagai\nlayanan CareGo',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: _registerMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF0E7FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person_add_alt_1_rounded,
              color: _registerPurple, size: 34),
        ),
      ],
    );
  }
}

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    required this.icon,
    required this.hint,
    this.suffix,
    this.controller,
    this.obscure = false,
    this.keyboardType,
  });

  final IconData icon;
  final String hint;
  final Widget? suffix;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _registerPurple, size: 21),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA0B9), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _registerLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _registerLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _registerPurple, width: 1.3),
        ),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_registerPurple, _registerPurpleDark]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _RegisterWaveBackground extends StatelessWidget {
  const _RegisterWaveBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RegisterWavePainter());
  }
}

class _RegisterWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pink = Paint()..color = const Color(0xFFFFEAF6);
    final purple = Paint()..color = const Color(0xFFEDE1FF);

    final pinkPath = Path()
      ..moveTo(0, size.height * .88)
      ..cubicTo(size.width * .2, size.height * .84, size.width * .38,
          size.height * .98, size.width * .58, size.height * .92)
      ..cubicTo(size.width * .78, size.height * .86, size.width * .88,
          size.height * .79, size.width, size.height * .78)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(pinkPath, pink);

    final purplePath = Path()
      ..moveTo(0, size.height * .94)
      ..cubicTo(size.width * .22, size.height * .9, size.width * .42,
          size.height, size.width * .62, size.height * .95)
      ..cubicTo(size.width * .8, size.height * .91, size.width * .9,
          size.height * .87, size.width, size.height * .86)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(purplePath, purple);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
