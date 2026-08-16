library;

import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/services/dlna/stage_slide_painter.dart';
import '../../../core/services/dlna/stage_settings_repository.dart';

/// Personalização do Palco: cores, fonte, tamanho — com preview ao vivo
/// (proporção 16:9 da TV). Persiste em disco ao salvar.
class StageCustomizationSheet extends StatefulWidget {
  final StageSettings initial;
  final ValueChanged<StageSettings> onApply;

  const StageCustomizationSheet({
    super.key,
    required this.initial,
    required this.onApply,
  });

  @override
  State<StageCustomizationSheet> createState() =>
      _StageCustomizationSheetState();
}

class _StageCustomizationSheetState extends State<StageCustomizationSheet> {
  late StageSettings _s;
  final _repo = StageSettingsRepository();

  static const _bgPresets = [
    (0xFF0A0E1A, 'Azul-noite'),
    (0xFF000000, 'Preto'),
    (0xFF1B2A1F, 'Verde-pastoral'),
    (0xFF2A1B1B, 'Vinho'),
  ];

  static const _fgPresets = [
    (0xFFFFFFFF, 'Branco'),
    (0xFFFFE9A8, 'Amarelo suave'),
    (0xFFB8E0FF, 'Azul claro'),
  ];

  @override
  void initState() {
    super.initState();
    _s = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personalizar Palco', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            // Preview 16:9 com texto de amostra
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: _s.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'O nosso sol\nVeio iluminar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      // escala preview: 96px em 1920 → ~proporcional
                      fontSize: (_s.fontSize / 1920) *
                          (MediaQuery.of(context).size.width - 64),
                      fontWeight: _s.fontWeight,
                      color: _s.textColor,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('Cor de fundo', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (c, label) in _bgPresets)
                  _colorChip(theme, Color(c), label, _s.backgroundColor,
                      (v) => setState(() => _s = _s.copyWith(backgroundColor: v))),
              ],
            ),
            const SizedBox(height: 16),

            Text('Cor do texto', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (c, label) in _fgPresets)
                  _colorChip(theme, Color(c), label, _s.textColor,
                      (v) => setState(() => _s = _s.copyWith(textColor: v))),
              ],
            ),
            const SizedBox(height: 16),

            Text('Tamanho da fonte: ${_s.fontSize.round()} px',
                style: theme.textTheme.labelLarge),
            Slider(
              min: 60,
              max: 160,
              value: _s.fontSize.clamp(60, 160),
              onChanged: (v) => setState(() => _s = _s.copyWith(fontSize: v)),
            ),

            Text('Espessura', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            SegmentedButton<FontWeight>(
              segments: const [
                ButtonSegment(value: FontWeight.w400, label: Text('Normal')),
                ButtonSegment(value: FontWeight.w600, label: Text('Média')),
                ButtonSegment(value: FontWeight.w800, label: Text('Forte')),
              ],
              selected: {_s.fontWeight},
              onSelectionChanged: (sel) =>
                  setState(() => _s = _s.copyWith(fontWeight: sel.first)),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(TablerIcons.rotate),
                    label: const Text('Redefinir'),
                    onPressed: () =>
                        setState(() => _s = const StageSettings()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(TablerIcons.check),
                    label: const Text('Aplicar'),
                    onPressed: () async {
                      await _repo.save(_s);
                      widget.onApply(_s);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorChip(ThemeData theme, Color c, String label, Color selected,
      ValueChanged<Color> onTap) {
    final isSel = selected.toARGB32() == c.toARGB32();
    return InputChip(
      avatar: CircleAvatar(backgroundColor: c, radius: 9),
      label: Text(label),
      selected: isSel,
      onPressed: () => onTap(c),
      showCheckmark: false,
      side: isSel
          ? BorderSide(color: theme.colorScheme.primary, width: 2)
          : null,
    );
  }
}
