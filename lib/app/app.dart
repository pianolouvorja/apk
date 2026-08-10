library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import '../core/services/settings_controller.dart';
import '../presentation/splash/splash_screen.dart';
import 'router.dart';
import 'theme/app_accents.dart';
import 'theme/app_theme.dart';

class LouvorjaApp extends StatefulWidget {
  const LouvorjaApp({super.key});

  @override
  State<LouvorjaApp> createState() => _LouvorjaAppState();
}

class _LouvorjaAppState extends State<LouvorjaApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Libera a splash nativa após o primeiro frame. A splash Flutter interna
    // assume a apresentação com logo LouvorJA + codename PIANO + loader.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        FlutterNativeSplash.remove();
      }
    });
  }

  void _hideSplash() {
    if (mounted) {
      if (!kIsWeb) {
        FlutterNativeSplash.remove();
      }
      setState(() => _showSplash = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final accent = AppAccents.byId(settings.accent.name);

    return MaterialApp.router(
      title: 'LouvorJA PIANO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: accent),
      darkTheme: AppTheme.dark(accent: accent),
      themeMode: settings.themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: appRouter,
      builder: (context, child) {
        if (_showSplash) {
          return SplashScreen(onInitializationComplete: _hideSplash);
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
