import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 86});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/carego_logo.png',
      width: size,
      fit: BoxFit.contain,
    );
  }
}
