/// Entry point do LouvorJA PIANO Mobile.
library;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/app.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: binding);
  }
  runApp(const LouvorjaApp());
}
