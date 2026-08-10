library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../app/theme/app_accents.dart';
import '../../core/constants/app_version.dart';
import '../../core/services/settings_controller.dart';

/// SettingsPage — tela de configuracoes (tab "Mais").
///
/// Fonte: pianolouvorja/app/src/modules/settings/views/AppearanceView.vue
/// + GeneralView.vue
///
/// Secoes (adaptadas do Electron, sem projecao/media):
/// 1. Aparencia: tema, cor de acento, perfil de interacao, intensidade glass
/// 2. Geral: idioma, versao do app
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.title'.tr()),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Aparencia ---
          _SectionHeader(
            icon: TablerIcons.palette,
            title: 'settings.appearance'.tr(),
          ),
          const SizedBox(height: 12),

          // Tema
          _SettingsCard(
            icon: TablerIcons.moon,
            title: 'settings.theme'.tr(),
            child: Wrap(
              spacing: 8,
              children: [
                _ChoiceChip<ThemeMode>(
                  label: 'settings.themeDark'.tr(),
                  selected: settings.themeMode == ThemeMode.dark,
                  onTap: () => settings.setThemeMode(ThemeMode.dark),
                ),
                _ChoiceChip<ThemeMode>(
                  label: 'settings.themeLight'.tr(),
                  selected: settings.themeMode == ThemeMode.light,
                  onTap: () => settings.setThemeMode(ThemeMode.light),
                ),
                _ChoiceChip<ThemeMode>(
                  label: 'settings.themeSystem'.tr(),
                  selected: settings.themeMode == ThemeMode.system,
                  onTap: () => settings.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Cor de acento
          _SettingsCard(
            icon: TablerIcons.colorSwatch,
            title: 'settings.accentColor'.tr(),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AccentKey.values.map((key) {
                final accent = AppAccents.byId(key.name);
                final isSelected = settings.accent == key;
                return GestureDetector(
                  onTap: () => settings.setAccent(key),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.primary,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Perfil de interacao
          _SettingsCard(
            icon: TablerIcons.keyframes,
            title: 'settings.animationProfile'.tr(),
            child: Wrap(
              spacing: 8,
              children: InteractionKey.values.map((key) {
                final labels = {
                  InteractionKey.dynamic_: 'Dynamic',
                  InteractionKey.soft: 'Soft',
                  InteractionKey.mist: 'Mist',
                };
                return _ChoiceChip<InteractionKey>(
                  label: labels[key]!,
                  selected: settings.interaction == key,
                  onTap: () => settings.setInteraction(key),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Intensidade do glass
          _SettingsCard(
            icon: TablerIcons.blur,
            title: 'settings.glassIntensity'.tr(),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: settings.glassIntensity.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${settings.glassIntensity}%',
                    onChanged: (v) => settings.setGlassIntensity(v.round()),
                  ),
                ),
                Text('${settings.glassIntensity}%'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- Geral ---
          _SectionHeader(
            icon: TablerIcons.adjustments,
            title: 'Geral',
          ),
          const SizedBox(height: 12),

          // Idioma
          _SettingsCard(
            icon: TablerIcons.language,
            title: 'settings.language'.tr(),
            child: Wrap(
              spacing: 8,
              children: [
                _ChoiceChip(
                  label: 'Portugues (BR)',
                  selected: context.locale == const Locale('pt', 'BR'),
                  onTap: () => context.setLocale(const Locale('pt', 'BR')),
                ),
                _ChoiceChip(
                  label: 'English',
                  selected: context.locale == const Locale('en'),
                  onTap: () => context.setLocale(const Locale('en')),
                ),
                _ChoiceChip(
                  label: 'Espanol',
                  selected: context.locale == const Locale('es'),
                  onTap: () => context.setLocale(const Locale('es')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Versao
          FutureBuilder<String>(
            future: AppVersion.displayVersion,
            builder: (context, snapshot) {
              return _SettingsCard(
                icon: TablerIcons.infoCircle,
                title: 'Versao',
                child: Text(
                  snapshot.data ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Termos e Privacidade (link)
          ListTile(
            leading: Icon(TablerIcons.shieldCheck, color: theme.colorScheme.primary),
            title: const Text('Termos de Uso e Privacidade'),
            trailing: const Icon(TablerIcons.chevronRight),
            onTap: () {
              // TODO: Fase 6 - abrir termos
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip<T> extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? theme.colorScheme.primary : null,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
      ),
    );
  }
}
