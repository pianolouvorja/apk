library;

import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/services/dlna/stage_slide_painter.dart';
import '../../../core/services/dlna/stage_settings_repository.dart';
import '../../../core/services/dlna/stage_session.dart';

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

  /// BG atual (imagem salva do usuário); null = usa bg-fallback do Palco.
  Uint8List? _bgBytes;

  static const _officialBackgrounds = [
    'assets/backgrounds/bg-01.png',
    'assets/backgrounds/bg-02.png',
    'assets/backgrounds/bg-03.png',
    'assets/backgrounds/bg-04.png',
    'assets/backgrounds/bg-05.png',
    'assets/backgrounds/bg-06.png',
    'assets/backgrounds/bg-07.png',
    'assets/backgrounds/bg-08.png',
    'assets/backgrounds/bg-09.png',
    'assets/backgrounds/bg-10.png',
  ];

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

  // F3.3o: cores da referência da Bíblia (rodapé).
  static const _refPresets = [
    (0xFFFCCE02, 'Dourado'),
    (0xFFFFFFFF, 'Branco'),
    (0xFF00C1E6, 'Ciano'),
    (0xFFFFE9A8, 'Amarelo suave'),
  ];

  @override
  void initState() {
    super.initState();
    _s = widget.initial;
    _loadBgPreview();
  }

  /// Carrega o BG salvo pro preview. Sem imagem → bg-fallback (asset oficial).
  Future<void> _loadBgPreview() async {
    final bytes = await _repo.loadBackgroundImage();
    if (!mounted) return;
    setState(() => _bgBytes = bytes);
  }

  Future<void> _chooseOfficialBackground() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Galeria de fundos',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: MediaQuery.of(sheetContext).size.height * .55,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 16 / 9,
                  ),
                  itemCount: _officialBackgrounds.length,
                  itemBuilder: (_, index) => InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pop(
                      sheetContext,
                      _officialBackgrounds[index],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        _officialBackgrounds[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    final data = await rootBundle.load(chosen);
    await StageSession.instance.setBackgroundBytes(data.buffer.asUint8List());
    await _loadBgPreview();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personalizar Palco', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            // Preview 16:9 com texto de amostra — mostra o BG REAL (imagem
            // salva ou bg-fallback oficial) por trás, como a TV renderiza.
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: _s.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // BG real: imagem do usuário (cover) ou fallback oficial.
                      if (_bgBytes != null)
                        Image.memory(_bgBytes!, fit: BoxFit.cover)
                      else
                        Image.asset(
                          'assets/palco/bg-fallback.png',
                          fit: BoxFit.cover,
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          // Caixinha atrás da letra — igual o receiver
                          // (rgba preto com opacidade configurável).
                          decoration: _s.textBox
                              ? BoxDecoration(
                                  color: Colors.black.withValues(
                                    alpha: _s.boxOpacity,
                                  ),
                                  border: _s.boxBorder
                                      ? Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.25,
                                          ),
                                        )
                                      : null,
                                )
                              : null,
                          padding: _s.textBox
                              ? const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                )
                              : EdgeInsets.zero,
                          child: Text(
                            'O nosso sol\nVeio iluminar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              // escala preview: 96px em 1920 → ~proporcional
                              fontSize:
                                  (_s.fontSize / 1920) *
                                  (MediaQuery.of(context).size.width - 64),
                              fontWeight: _s.fontWeight,
                              color: _s.textColor,
                              height: 1.35,
                              // Sombra da letra — igual o receiver
                              // (blur e intensidade configuráveis).
                              shadows: _s.textShadow
                                  ? [
                                      Shadow(
                                        color: Colors.black.withValues(
                                          alpha: _s.shadowIntensity,
                                        ),
                                        blurRadius:
                                            _s.shadowBlur *
                                            ((MediaQuery.of(
                                                      context,
                                                    ).size.width -
                                                    64) /
                                                1920),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                  _colorChip(
                    theme,
                    Color(c),
                    label,
                    _s.backgroundColor,
                    (v) => setState(() => _s = _s.copyWith(backgroundColor: v)),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Imagem de fundo (movida do menu do caster — menos é mais:
            // tudo visual do palco mora aqui no Personalizar).
            Text('Imagem de fundo', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  icon: const Icon(TablerIcons.layoutGrid),
                  label: const Text('Fundos oficiais'),
                  onPressed: _chooseOfficialBackground,
                ),
                OutlinedButton.icon(
                  icon: const Icon(TablerIcons.upload),
                  label: const Text('Imagem do aparelho'),
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 90,
                    );
                    if (picked == null) return;
                    await StageSession.instance.setBackgroundFromFile(
                      picked.path,
                    );
                    await _loadBgPreview();
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('stage.backgroundUpdated'.tr())),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text('Cor do texto', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (c, label) in _fgPresets)
                  _colorChip(
                    theme,
                    Color(c),
                    label,
                    _s.textColor,
                    (v) => setState(() => _s = _s.copyWith(textColor: v)),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Tamanho da fonte: ${_s.fontSize.round()} px',
              style: theme.textTheme.labelLarge,
            ),
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

            // ===== F3.3o: Bíblia — tipografia própria =====
            const Divider(),
            Text(
              'Bíblia — aparência própria',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            Text('Cor do texto (Bíblia)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (c, label) in _fgPresets)
                  _colorChip(
                    theme,
                    Color(c),
                    label,
                    _s.bibleTextColor,
                    (v) => setState(() => _s = _s.copyWith(bibleTextColor: v)),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Tamanho da fonte: ${_s.bibleFontSize.round()} px',
              style: theme.textTheme.labelLarge,
            ),
            Slider(
              min: 50,
              max: 140,
              value: _s.bibleFontSize.clamp(50, 140),
              onChanged: (v) =>
                  setState(() => _s = _s.copyWith(bibleFontSize: v)),
            ),

            Text('Espessura (Bíblia)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 400, label: Text('Normal')),
                ButtonSegment(value: 500, label: Text('Leve+')),
                ButtonSegment(value: 700, label: Text('Forte')),
              ],
              selected: {_s.bibleFontWeight},
              onSelectionChanged: (sel) =>
                  setState(() => _s = _s.copyWith(bibleFontWeight: sel.first)),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar versão da Bíblia no rodapé'),
              value: _s.showBibleVersion,
              onChanged: (v) =>
                  setState(() => _s = _s.copyWith(showBibleVersion: v)),
            ),

            Text(
              'Cor da referência (rodapé)',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (c, label) in _refPresets)
                  _colorChip(
                    theme,
                    Color(c),
                    label,
                    _s.footerRefColor,
                    (v) => setState(() => _s = _s.copyWith(footerRefColor: v)),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ===== F3.3m: sombra e caixinha =====
            const Divider(),
            Text('Sombra e caixinha', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sombra na letra'),
              value: _s.textShadow,
              onChanged: (v) => setState(() => _s = _s.copyWith(textShadow: v)),
            ),
            if (_s.textShadow) ...[
              Text('Intensidade da sombra', style: theme.textTheme.labelLarge),
              Slider(
                min: 0.2,
                max: 1,
                value: _s.shadowIntensity,
                onChanged: (v) =>
                    setState(() => _s = _s.copyWith(shadowIntensity: v)),
              ),
              Text('Espalhamento da sombra', style: theme.textTheme.labelLarge),
              Slider(
                min: 0.5,
                max: 5,
                value: _s.shadowBlur,
                onChanged: (v) =>
                    setState(() => _s = _s.copyWith(shadowBlur: v)),
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Caixinha atrás da letra'),
              value: _s.textBox,
              onChanged: (v) => setState(() => _s = _s.copyWith(textBox: v)),
            ),
            if (_s.textBox) ...[
              Text('Opacidade da caixinha', style: theme.textTheme.labelLarge),
              Slider(
                min: 0.1,
                max: 0.9,
                value: _s.boxOpacity,
                onChanged: (v) =>
                    setState(() => _s = _s.copyWith(boxOpacity: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Borda na caixinha'),
                value: _s.boxBorder,
                onChanged: (v) =>
                    setState(() => _s = _s.copyWith(boxBorder: v)),
              ),
            ],
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(TablerIcons.rotate),
                    label: const Text('Redefinir'),
                    onPressed: () => setState(() => _s = const StageSettings()),
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

  Widget _colorChip(
    ThemeData theme,
    Color c,
    String label,
    Color selected,
    ValueChanged<Color> onTap,
  ) {
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
