library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget que mostra o codinome "PIANO" com as barras coloridas.
///
/// Fonte: pianolouvorja/app/src/assets/brand/codenamePIANO.svg
/// + CodenameLogo.vue (currentCor dinâmico baseado no tema)
class CodenamePiano extends StatelessWidget {
  final double width;

  const CodenamePiano({super.key, this.width = 200});

  @override
  Widget build(BuildContext context) {
    // Não aplicar ColorFilter: o asset oficial tem barras azul/ciano/amarela.
    // Tintir todo o SVG destruiria a identidade visual do codename PIANO.
    // O SplashScreen usa Ethereal Lumens como o Electron, onde a tipografia
    // branca do asset é intencionalmente visível.
    return SvgPicture.asset(
      'assets/images/codename-piano.svg',
      width: width,
    );
  }
}
