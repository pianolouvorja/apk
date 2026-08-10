library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget que mostra o codinome "PIANO" com as barras coloridas.
///
/// Fonte: pianolouvorja/app/src/assets/brand/codenamePIANO.svg
/// + CodenameLogo.vue
///
/// No Electron: dark = currentColor branco, light = currentColor preto.
/// As barras azul/ciano/amarela sao sempre preservadas (cores fixas).
///
/// No Flutter: dois SVGs separados com fill explicito
/// (dark = letras #FFFFFF, light = letras #000000).
/// As barras coloridas (#04549B, #00C1E6, #FCCE02) sao identicas em ambos.
class CodenamePiano extends StatelessWidget {
  final double width;

  const CodenamePiano({super.key, this.width = 200});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SvgPicture.asset(
      isDark
          ? 'assets/images/codename-piano-dark.svg'
          : 'assets/images/codename-piano-light.svg',
      width: width,
    );
  }
}
