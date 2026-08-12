library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:louvorja_piano_mobile/data/repositories/countdown_preset_repository.dart';
import 'package:louvorja_piano_mobile/domain/entities/countdown_preset.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('salva e recarrega presets ordenados', () async {
    final repository = CountdownPresetRepository();
    final presets = [
      const CountdownPreset(
        id: 'culto',
        label: 'Início do culto',
        duration: Duration(minutes: 5),
      ),
      const CountdownPreset(
        id: 'sermao',
        label: 'Sermão',
        duration: Duration(minutes: 40),
      ),
    ];

    await repository.save(presets);
    final loaded = await repository.load();

    expect(loaded.map((preset) => preset.id), ['culto', 'sermao']);
    expect(loaded[1].duration, const Duration(minutes: 40));
  });

  test('retorna vazio para armazenamento inválido', () async {
    SharedPreferences.setMockInitialValues({
      'timer.countdown.presets.v1': 'invalido',
    });

    expect(await CountdownPresetRepository().load(), isEmpty);
  });

  test('descarta presets sem identificador ou duração', () async {
    SharedPreferences.setMockInitialValues({
      'timer.countdown.presets.v1':
          '[{"id":"ok","label":"OK","seconds":60},{"id":"","label":"Sem id","seconds":5},{"id":"zero","label":"Zero","seconds":0}]',
    });

    final loaded = await CountdownPresetRepository().load();
    expect(loaded, hasLength(1));
    expect(loaded.single.label, 'OK');
  });
}
