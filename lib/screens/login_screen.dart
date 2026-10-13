import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/app_store.dart';
import '../models/app_models.dart';
import '../utils/app_routes.dart';

const _authPurple = Color(0xFF663CE2);
const _authPurpleDark = Color(0xFF4E2ED0);
const _authInk = Color(0xFF11173F);
const _authMuted = Color(0xFF73799A);
const _authLine = Color(0xFFE6E2F6);
const _authSurface = Color(0xFFFFFBFF);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AppRole? registrationRole;
  var roleLoaded = false;
  var obscure = true;
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();
  var submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!roleLoaded) {
      registrationRole = ModalRoute.of(context)?.settings.arguments as AppRole?;
      roleLoaded = true;
    }
  }

  Future<void> _login() async {
    setState(() => submitting = true);
    try {
      await AppStore.instance.login(
        email: identifierController.text.trim(),
        password: passwordController.text,
        expectedRole: registrationRole,
      );
      if (!mounted) return;
      final user = AppStore.instance.currentUser;
      final route = switch (user?.role ?? AppRole.user) {
        AppRole.user => AppRoutes.userDashboard,
        AppRole.mitra => AppStore.instance.currentMitra?.isApproved == true
            ? AppRoutes.partnerDashboard
            : AppRoutes.registrationStatus,
        AppRole.pelayan => AppRoutes.employeeDashboard,
        AppRole.admin => AppRoutes.adminDashboard,
      };
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void _register() {
    final role = registrationRole ?? AppRole.user;
    final route = switch (role) {
      AppRole.user => AppRoutes.register,
      AppRole.mitra => AppRoutes.partnerRegister,
      AppRole.pelayan => AppRoutes.employeeRegister,
      AppRole.admin => AppRoutes.register,
    };
    Navigator.pushNamed(context, route, arguments: role);
  }

  void _googleLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Login Google siap di UI. Koneksi OAuth belum diaktifkan.'),
      ),
    );
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _showApiServerDialog() async {
    final rootContext = context;
    final store = AppStore.instance;
    final controller = TextEditingController(text: store.apiBaseUrl);
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Alamat API Server'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan URL ngrok atau server CareGo Anda.',
                style: TextStyle(fontSize: 12, color: _authMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Alamat API'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      try {
                        await store.updateApiBaseUrl(controller.text);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(rootContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Alamat API diperbarui ke ${store.apiBaseUrl}',
                            ),
                          ),
                        );
                        if (mounted) setState(() {});
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(rootContext).showSnackBar(
                          SnackBar(content: Text('$error')),
                        );
                        setDialogState(() => saving = false);
                      }
                    },
              child: Text(saving ? 'Menyimpan...' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _authSurface,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _AuthWaveBackground()),
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
                            color: _authInk, size: 20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const _LoginCardHeader(),
                    const SizedBox(height: 22),
                    _AuthField(
                      icon: Icons.mail_outline_rounded,
                      hint: 'Email atau Nomor HP',
                      controller: identifierController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _AuthField(
                      icon: Icons.lock_outline_rounded,
                      hint: 'Kata Sandi',
                      obscure: obscure,
                      suffix: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _authMuted,
                        ),
                      ),
                      controller: passwordController,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: _authPurple,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Lupa Kata Sandi?',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _GradientButton(
                      label: submitting ? 'Menghubungkan...' : 'Masuk',
                      onPressed: submitting ? null : _login,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: submitting ? null : _showApiServerDialog,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: _authLine),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.dns_outlined, color: _authPurple),
                      label: Text(
                        'Alamat API: ${AppStore.instance.apiBaseUrl}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _authInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _DividerLabel(text: 'atau masuk dengan'),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: _SocialAuthButton(
                        label: 'Google',
                        icon: const Text(
                          'G',
                          style: TextStyle(
                            color: Color(0xFF4285F4),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        onPressed: _googleLogin,
                      ),
                    ),
                    const SizedBox(height: 34),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text('Belum punya akun? ',
                            style: TextStyle(
                                color: _authMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        GestureDetector(
                          onTap: _register,
                          child: const Text(
                            'Daftar Sekarang',
                            style: TextStyle(
                              color: _authPurple,
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

class _LoginCardHeader extends StatelessWidget {
  const _LoginCardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang Kembali \u{1F44B}',
                style: TextStyle(
                  color: _authInk,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Masuk untuk melanjutkan\nperawatan terbaikmu',
                style: TextStyle(
                  color: _authMuted,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 130,
          height: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3ECFF),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: _authPurple.withValues(alpha: .12),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child:
              Image.asset('assets/images/login_house.png', fit: BoxFit.contain),
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.icon,
    required this.hint,
    this.obscure = false,
    this.suffix,
    this.controller,
    this.keyboardType,
  });

  final IconData icon;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _authPurple, size: 21),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA0B9), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _authLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _authLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _authPurple, width: 1.3),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_authPurple, _authPurpleDark]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _authPurple.withValues(alpha: .22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
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

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider(color: _authLine)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child:
            Text(text, style: const TextStyle(color: _authMuted, fontSize: 12)),
      ),
      const Expanded(child: Divider(color: _authLine)),
    ]);
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _authInk,
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: _authLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _AuthWaveBackground extends StatelessWidget {
  const _AuthWaveBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AuthWavePainter());
  }
}

class _AuthWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintPink = Paint()..color = const Color(0xFFFFEAF6);
    final paintPurple = Paint()..color = const Color(0xFFEDE1FF);

    final pinkPath = Path()
      ..moveTo(0, size.height * .88)
      ..cubicTo(size.width * .25, size.height * .82, size.width * .42,
          size.height, size.width * .66, size.height * .9)
      ..cubicTo(size.width * .82, size.height * .84, size.width * .9,
          size.height * .78, size.width, size.height * .77)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(pinkPath, paintPink);

    final purplePath = Path()
      ..moveTo(0, size.height * .94)
      ..cubicTo(size.width * .23, size.height * .86, size.width * .42,
          size.height * .95, size.width * .58, size.height * .98)
      ..cubicTo(size.width * .75, size.height, size.width * .86,
          size.height * .91, size.width, size.height * .88)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(purplePath, paintPurple);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
