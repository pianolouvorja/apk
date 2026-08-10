library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../shared/widgets/codename_piano.dart';
import '../shared/widgets/louvorja_logo.dart';

/// Tela de splash — mostra logo + codinome PIANO durante boot.
///
/// Fonte: pianolouvorja/app/src/modules/starting/
/// Overlay visivel durante inicializacao com logo + codinome + status.
class SplashScreen extends StatefulWidget {
  final VoidCallback? onInitializationComplete;

  const SplashScreen({
    super.key,
    this.onInitializationComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeLogo;
  late final Animation<double> _fadeCodename;
  late final Animation<double> _fadeStatus;
  Timer? _bootTimer;
  bool _completed = false;

  void _completeInitialization() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onInitializationComplete?.call();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeLogo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _fadeCodename = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );
    _fadeStatus = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    // Boot mínimo visual. Será substituído pelo bootstrap real de catálogo.
    _bootTimer = Timer(const Duration(milliseconds: 2200), _completeInitialization);
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // O boot desktop usa Ethereal Lumens independente da preferência salva.
      // Também garante contraste com o codename oficial branco/colorido.
      backgroundColor: EtherealLumensColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo LouvorJA
            FadeTransition(
              opacity: _fadeLogo,
              child: const LouvorJaLogo(size: 140),
            ),
            const SizedBox(height: 32),

            // Codinome PIANO
            FadeTransition(
              opacity: _fadeCodename,
              child: const CodenamePiano(width: 220),
            ),
            const SizedBox(height: 48),

            // Status / loading
            FadeTransition(
              opacity: _fadeStatus,
              child: Column(
                children: [
                  // Spinner circular simples na cor primary
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'v0.1.0-alpha',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
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
