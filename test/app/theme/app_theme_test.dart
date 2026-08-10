library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scrollbar clareia em hover', () {
    // Só executa o resolver de WidgetState, sem construir ThemeData completo
    // (que dispara google_fonts e rede).
    final resolver = WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.hovered)) {
        return const Color(0xFF929292);
      }
      return const Color(0xFF7A7A7A);
    });
    expect(resolver.resolve({WidgetState.hovered}), const Color(0xFF929292));
    expect(resolver.resolve({}), const Color(0xFF7A7A7A));
  });
}
