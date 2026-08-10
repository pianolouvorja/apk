library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/app_spacing.dart';
import '../shared/widgets/gradient_background.dart';

/// HomePage — tela inicial identica ao app desktop.
///
/// Fonte: pianolouvorja/app/src/modules/home/views/HomeView.vue
///
/// Layout centralizado:
/// - Logo LouvorJA (128px)
/// - Campo editavel: Distrito (lg)
/// - Campo editavel: Igreja (md)
/// - Relogio digital em tempo real (32px, cor primary, glow)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DateTime _now;
  Timer? _clockTimer;
  final _districtController = TextEditingController();
  final _churchController = TextEditingController();
  bool _editingDistrict = true;
  bool _editingChurch = false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _districtController.dispose();
    _churchController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pageMargin),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo LouvorJA 128px centralizado
                SvgPicture.asset(
                  'assets/images/logo-louvor-ja.svg',
                  width: 128,
                  height: 128,
                ),
                const SizedBox(height: 40),

                // Distrito (editavel, size lg)
                _LocationField(
                  label: 'Distrito',
                  fontSize: 24,
                  controller: _districtController,
                  editing: _editingDistrict,
                  onEdit: () => setState(() => _editingDistrict = true),
                  onSubmit: (value) => setState(() {
                    _districtController.text = value;
                    _editingDistrict = false;
                    _editingChurch = _churchController.text.isEmpty;
                  }),
                ),
                const SizedBox(height: 12),

                // Igreja (editavel, size md)
                _LocationField(
                  label: 'Igreja',
                  fontSize: 18,
                  controller: _churchController,
                  editing: _editingChurch,
                  onEdit: () => setState(() => _editingChurch = true),
                  onSubmit: (value) => setState(() {
                    _churchController.text = value;
                    _editingChurch = false;
                  }),
                ),
                const SizedBox(height: 24),

                // Relogio digital em tempo real
                Text(
                  _formattedTime,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: theme.colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    shadows: [
                      Shadow(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final String label;
  final double fontSize;
  final TextEditingController controller;
  final bool editing;
  final VoidCallback onEdit;
  final ValueChanged<String> onSubmit;

  const _LocationField({
    required this.label,
    required this.fontSize,
    required this.controller,
    required this.editing,
    required this.onEdit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = controller.text.trim().isNotEmpty;

    if (editing) {
      return SizedBox(
        width: 320,
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          autofocus: true,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
          ),
          onSubmitted: onSubmit,
        ),
      );
    }

    return GestureDetector(
      onTap: onEdit,
      child: Text(
        filled ? controller.text : label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
          color: filled
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
