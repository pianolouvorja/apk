// Entry point do LouvorJA PIANO Mobile.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:easy_localization/easy_localization.dart';

import 'app/app.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: binding);
  }

  // App operador: fixar em portrait (nao faz sentido landscape no celular)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('pt', 'BR'), Locale('en'), Locale('es')],
      path: 'assets/translations',
      fallbackLocale: const Locale('pt', 'BR'),
      // Sem startLocale: easy_localization detecta o idioma do OS.
      // saveLocale true (default): se o usuario trocar nas Configuracoes,
      // a escolha persiste em SharedPreferences e sobrescreve o OS locale.
      child: const LouvorjaApp(),
    ),
  );
}
