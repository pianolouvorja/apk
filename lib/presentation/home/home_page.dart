library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/gradient_background.dart';
import '../shared/widgets/louvorja_logo.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return GradientBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pageMargin),
          children: [
            _buildHeader(context, theme),
            const SizedBox(height: AppSpacing.s6),
            _buildDateCard(context, theme, now),
            const SizedBox(height: AppSpacing.s6),
            _buildShortcuts(context, theme),
            const SizedBox(height: AppSpacing.s6),
            _buildFooter(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        const LouvorJaLogo(size: 48),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LouvorJA',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'PIANO',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateCard(BuildContext context, ThemeData theme, DateTime now) {
    final weekdays = [
      'Domingo', 'Segunda-feira', 'Terça-feira',
      'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'
    ];
    final months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    final dateStr =
        '${weekdays[now.weekday % 7]}, ${now.day} de ${months[now.month - 1]}';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Bem-vindo! Use os atalhos abaixo para acessar rapidamente o que precisa para o culto.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcuts(BuildContext context, ThemeData theme) {
    final shortcuts = [
      _Shortcut(icon: TablerIcons.playlist, label: 'Hinos', route: '/hymns'),
      _Shortcut(
          icon: TablerIcons.clipboardText,
          label: 'Liturgia',
          route: '/liturgy'),
      _Shortcut(icon: TablerIcons.book2, label: 'Bíblia', route: '/bible'),
      _Shortcut(icon: TablerIcons.hourglass, label: 'Timer', route: '/timer'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.s3,
        crossAxisSpacing: AppSpacing.s3,
        childAspectRatio: 2.2,
      ),
      itemCount: shortcuts.length,
      itemBuilder: (context, index) {
        final s = shortcuts[index];
        return Material(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: AppRadius.lg,
          child: InkWell(
            onTap: () => context.push(s.route),
            borderRadius: AppRadius.lg,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Row(
                children: [
                  Icon(s.icon, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Text(
                      s.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    TablerIcons.chevronRight,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    return GlassCard(
      blurIntensity: 30,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      child: Row(
        children: [
          Icon(
            TablerIcons.infoCircle,
            color: theme.colorScheme.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              'v0.1.0-alpha — Em desenvolvimento',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Shortcut {
  final IconData icon;
  final String label;
  final String route;

  const _Shortcut({
    required this.icon,
    required this.label,
    required this.route,
  });
}
