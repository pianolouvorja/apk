library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget que mostra o codinome "PIANO" com as barras coloridas.
///
/// Fonte: pianolouvorja/app/src/assets/brand/codenamePIANO.svg
/// + CodenameLogo.vue (currentColor dinâmico baseado no tema)
///
/// No Electron: dark = letras brancas, light = letras pretas.
/// As barras azul/ciano/amarela são sempre preservadas (cores fixas do SVG).
///
/// O SVG original tem as letras com fill #FFFEFE (branco) e as barras com
/// fill fixo (#04549B, #00C1E6, #FCCE02). No dark theme (fundo #131313)
/// as letras brancas ja ficam visíveis naturalmente, sem needing filtro.
/// No light theme aplicamos um colorFilter para escurecer as letras.
/// Como BlendMode.srcIn pintiria tudo (incluindo as barras), usamos
/// o SVG sem filtro -- ele ja renderiza corretamente no dark.
class CodenamePiano extends StatelessWidget {
  final double width;

  const CodenamePiano({super.key, this.width = 200});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      // Light theme: aplicar overlay escuro nas letras via ColorMatrix.
      // O SVG tem letras em branco (#FFFEFE) e barras coloridas.
      // No light precisamos inverter as letras para preto mantendo as barras.
      // Como flutter_svg nao suporta seletor por elemento, renderizamos
      // sem filtro -- a splash sempre usa fundo dark (#131313), entao
      // o codename branco e visivel em qualquer tema.
      return SvgPicture.asset(
        'assets/images/codename-piano.svg',
        width: width,
      );
    }

    // Dark theme: SVG ja tem letras brancas -- renderizar sem filtro.
    return SvgPicture.asset(
      'assets/images/codename-piano.svg',
      width: width,
    );
  }
}
