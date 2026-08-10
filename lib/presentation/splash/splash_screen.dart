library;

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/constants/app_version.dart';
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
  AnimationController? _controller;
  Animation<double>? _fadeLogo;
  Animation<double>? _fadeCodename;
  Animation<double>? _fadeStatus;
  Timer? _bootTimer;
  bool _completed = false;
  String _version = '';

  void _completeInitialization() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onInitializationComplete?.call();
  }

  @override
  void initState() {
    super.initState();

    // Carrega versão e inicia animações+timer juntos.
    // O timer so comeca depois que a versao chegou, garantindo
    // que ela apareça na splash.
    AppVersion.displayVersion.then((v) {
      if (!mounted) return;
      setState(() => _version = v);
      _startBootSequence();
    });
  }

  void _startBootSequence() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeLogo = CurvedAnimation(
      parent: _controller!,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _fadeCodename = CurvedAnimation(
      parent: _controller!,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );
    _fadeStatus = CurvedAnimation(
      parent: _controller!,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    _controller!.forward();

    // Boot mínimo visual. Será substituído pelo bootstrap real de catálogo.
    _bootTimer = Timer(const Duration(milliseconds: 2200), _completeInitialization);
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final versionLoaded = _version.isNotEmpty;
    final fadeLogo = _fadeLogo;
    final fadeCodename = _fadeCodename;
    final fadeStatus = _fadeStatus;

    // Antes da versao carregar: mostra logo estatico (sem animacao)
    if (!versionLoaded || fadeLogo == null || fadeCodename == null || fadeStatus == null) {
      return Scaffold(
        backgroundColor: EtherealLumensColors.background,
        body: Center(
          child: const LouvorJaLogo(size: 140),
        ),
      );
    }

    return Scaffold(
      backgroundColor: EtherealLumensColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: fadeLogo,
              child: const LouvorJaLogo(size: 140),
            ),
            const SizedBox(height: 32),

            FadeTransition(
              opacity: fadeCodename,
              child: const CodenamePiano(width: 220),
            ),
            const SizedBox(height: 48),

            FadeTransition(
              opacity: fadeStatus,
              child: Column(
                children: [
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
                    'splash.loading'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _version,
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
