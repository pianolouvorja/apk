/// App root — MaterialApp.router com temas.
library;
import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class LouvorjaApp extends StatelessWidget {
  const LouvorjaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LouvorJA PIANO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
