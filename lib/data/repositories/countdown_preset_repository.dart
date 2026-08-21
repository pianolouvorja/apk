library;

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:louvorja_piano_mobile/core/services/sync/sync_timestamps.dart';

import '../../domain/entities/countdown_preset.dart';

class CountdownPresetRepository {
  static const _storageKey = 'timer.countdown.presets.v1';
  final Future<SharedPreferences> Function() _preferences;

  CountdownPresetRepository({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  Future<List<CountdownPreset>> load() async {
    final prefs = await _preferences();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map(
            (item) => CountdownPreset.fromJson(Map<String, dynamic>.from(item)),
          )
          .where(
            (preset) => preset.id.isNotEmpty && preset.duration > Duration.zero,
          )
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(List<CountdownPreset> presets) async {
    final prefs = await _preferences();
    await prefs.setString(
      _storageKey,
      jsonEncode(presets.map((preset) => preset.toJson()).toList()),
    );
    unawaited(SyncTimestamps.touch('timerPresets'));
  }
}
