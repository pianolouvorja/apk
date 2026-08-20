library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';

import 'stage_slide_painter.dart';

/// Persistência das personalizações do Palco (disk-backed, testável).
class StageSettingsRepository {
  static const _fileName = 'stage_settings.json';

  Future<File> _file() async =>
      File('${(await getApplicationDocumentsDirectory()).path}/$_fileName');

  Future<StageSettings> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return const StageSettings();
      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return StageSettings(
        backgroundColor: Color(j['bg'] as int? ?? 0xFF0A0E1A),
        textColor: Color(j['fg'] as int? ?? 0xFFFFFFFF),
        fontSize: (j['size'] as num?)?.toDouble() ?? 96,
        fontWeight: FontWeight.values.firstWhere(
          (w) => w.value == (j['weight'] as int? ?? 5),
          orElse: () => FontWeight.w600,
        ),
        margin: (j['margin'] as num?)?.toDouble() ?? 120,
        // F3.3m
        textShadow: j['tsOn'] as bool? ?? true,
        shadowBlur: (j['tsBlur'] as num?)?.toDouble() ?? 2.2,
        shadowIntensity: (j['tsInt'] as num?)?.toDouble() ?? 0.8,
        textBox: j['boxOn'] as bool? ?? false,
        boxOpacity: (j['boxBg'] as num?)?.toDouble() ?? 0.45,
        boxBorder: j['boxBorder'] as bool? ?? true,
        footerRefColor: Color(j['refColor'] as int? ?? 0xFFFCCE02),
        footerRefWeight: j['refWeight'] as int? ?? 600,
        showBibleVersion: j['showVer'] as bool? ?? true,
        // F3.3o
        bibleFontSize: (j['bSize'] as num?)?.toDouble() ?? 84,
        bibleFontWeight: j['bWeight'] as int? ?? 500,
        bibleTextColor: Color(j['bFg'] as int? ?? 0xFFFFFFFF),
      );
    } catch (_) {
      return const StageSettings();
    }
  }

  Future<void> save(StageSettings s) async {
    final f = await _file();
    await f.writeAsString(
      jsonEncode({
        'bg': s.backgroundColor.toARGB32(),
        'fg': s.textColor.toARGB32(),
        'size': s.fontSize,
        'weight': s.fontWeight.value,
        'margin': s.margin,
        // F3.3m
        'tsOn': s.textShadow,
        'tsBlur': s.shadowBlur,
        'tsInt': s.shadowIntensity,
        'boxOn': s.textBox,
        'boxBg': s.boxOpacity,
        'boxBorder': s.boxBorder,
        'refColor': s.footerRefColor.toARGB32(),
        'refWeight': s.footerRefWeight,
        'showVer': s.showBibleVersion,
        // F3.3o
        'bSize': s.bibleFontSize,
        'bWeight': s.bibleFontWeight,
        'bFg': s.bibleTextColor.toARGB32(),
      }),
    );
  }

  /// Imagem de fundo personalizada copiada pro dir do app.
  Future<String?> saveBackgroundImage(String sourcePath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/stage_bg.${sourcePath.split('.').last}');
      await File(sourcePath).copy(dest.path);
      return dest.path;
    } catch (_) {
      return null;
    }
  }

  /// Salva bytes de um BG empacotado (galeria oficial) no mesmo local do BG
  /// escolhido pelo usuário. Assim o resto do Palco continua agnóstico da fonte.
  Future<String?> saveBackgroundBytes(
    Uint8List bytes, {
    String ext = 'png',
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/stage_bg.$ext');
      await dest.writeAsBytes(bytes, flush: true);
      return dest.path;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> loadBackgroundImage() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/stage_bg.jpg');
      if (await f.exists()) return await f.readAsBytes();
      final f2 = File('${dir.path}/stage_bg.png');
      if (await f2.exists()) return await f2.readAsBytes();
    } catch (_) {}
    return null;
  }
}
