library;

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
  late final AnimationController _loaderController;
  late final Animation<double> _fadeLogo;
  late final Animation<double> _fadeCodename;
  late final Animation<double> _fadeStatus;
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
    _loaderController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat();

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

    // Simula boot de 2s depois chama callback
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        _completeInitialization();
      }
    });
  }

  @override
  void dispose() {
    _loaderController.dispose();
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
                  // Loader de marca: o logo LouvorJA gira continuamente
                  // enquanto o boot carrega, em vez de um spinner genérico.
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 42,
                          height: 42,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        RotationTransition(
                          turns: _loaderController,
                          child: const LouvorJaLogo(size: 24),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
