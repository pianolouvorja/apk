library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget que mostra o logo do LouvorJA (circulo com forma musical).
///
/// Fonte: pianolouvorja/app/src/assets/brand/logo-louvor-ja.svg
class LouvorJaLogo extends StatelessWidget {
  final double size;

  const LouvorJaLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo-louvor-ja.svg',
      width: size,
      height: size,
    );
  }
}
