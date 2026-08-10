library;

import 'package:flutter/material.dart';

import '../presentation/splash/splash_screen.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class LouvorjaApp extends StatefulWidget {
  const LouvorjaApp({super.key});

  @override
  State<LouvorjaApp> createState() => _LouvorjaAppState();
}

class _LouvorjaAppState extends State<LouvorjaApp> {
  bool _showSplash = true;

  void _hideSplash() {
    if (mounted) {
      setState(() => _showSplash = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LouvorJA PIANO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
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
