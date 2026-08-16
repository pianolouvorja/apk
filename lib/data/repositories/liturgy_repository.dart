library;

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:louvorja_piano_mobile/core/services/sync/sync_timestamps.dart';
import 'package:louvorja_piano_mobile/domain/entities/liturgy_item.dart';

/// Persistencia de liturgia por dia da semana usando SharedPreferences.
class LiturgyRepository {
  final SharedPreferences _prefs;

  static const _itemsPrefix = 'liturgy_items_';
  static const _notesPrefix = 'liturgy_notes_';

  LiturgyRepository(this._prefs);

  String _itemsKey(LiturgyWeekday day) => '$_itemsPrefix${day.name}';
  String _notesKey(LiturgyWeekday day) => '$_notesPrefix${day.name}';

  /// Carrega itens de um dia.
  List<LiturgyItem> loadItems(LiturgyWeekday day) {
    final raw = _prefs.getString(_itemsKey(day));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => LiturgyItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Salva itens de um dia.
  Future<void> saveItems(LiturgyWeekday day, List<LiturgyItem> items) async {
    final json = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_itemsKey(day), json);
    unawaited(SyncTimestamps.touch('liturgy'));
  }

  /// Carrega notas de um dia.
  String loadNotes(LiturgyWeekday day) {
    return _prefs.getString(_notesKey(day)) ?? '';
  }

  /// Salva notas de um dia.
  Future<void> saveNotes(LiturgyWeekday day, String notes) async {
    await _prefs.setString(_notesKey(day), notes);
    unawaited(SyncTimestamps.touch('liturgy'));
  }

  /// Clona liturgia de um dia para outro.
  Future<void> cloneDay(LiturgyWeekday from, LiturgyWeekday to) async {
    final items = loadItems(from);
    final notes = loadNotes(from);
    await saveItems(to, items);
    await saveNotes(to, notes);
  }

  /// Limpa liturgia de um dia.
  Future<void> clearDay(LiturgyWeekday day) async {
    await _prefs.remove(_itemsKey(day));
    await _prefs.remove(_notesKey(day));
  }
}
