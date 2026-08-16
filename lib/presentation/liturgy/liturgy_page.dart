// coverage:ignore-file
// ignore_for_file: deprecated_member_use
// UI de Liturgia
library;

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:louvorja_piano_mobile/presentation/shared/widgets/stage_cast_button.dart';
import 'package:louvorja_piano_mobile/core/services/dlna/stage_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import 'package:louvorja_piano_mobile/app/theme/app_spacing.dart';
import 'package:louvorja_piano_mobile/data/repositories/liturgy_repository.dart';
import 'package:louvorja_piano_mobile/domain/entities/liturgy_item.dart';
import 'package:louvorja_piano_mobile/presentation/liturgy/weekday_math.dart';
import 'package:louvorja_piano_mobile/presentation/liturgy/bloc/liturgy_bloc.dart';
import 'package:louvorja_piano_mobile/presentation/liturgy/services/liturgy_item_executor.dart';
import 'package:louvorja_piano_mobile/presentation/liturgy/widgets/liturgy_item_dialog.dart';

/// Converte LiturgyItemType enum para a chave snake_case do i18n.
String _typeToKey(dynamic type) {
  final name = type.toString().split('.').last;
  // camelCase -> snake_case
  final snake = name.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (m) => '_${m[0]!.toLowerCase()}',
  );
  return snake;
}

class LiturgyPage extends StatelessWidget {
  final LiturgyBloc? testBloc;

  const LiturgyPage({super.key, this.testBloc});

  @override
  Widget build(BuildContext context) {
    if (testBloc != null) {
      return BlocProvider<LiturgyBloc>.value(
        value: testBloc!,
        child: const _LiturgyView(),
      );
    }
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
            title: Text('liturgy.title'.tr()),
            actions: const [StageCastButton()],
          ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final bloc = LiturgyBloc(LiturgyRepository(snapshot.data!));
        bloc.add(LiturgyLoadRequested(_todayWeekday()));
        return BlocProvider<LiturgyBloc>.value(
          value: bloc,
          child: const _LiturgyView(),
        );
      },
    );
  }

  LiturgyWeekday _todayWeekday() => weekdayFromDart(DateTime.now().weekday);
}

class _LiturgyView extends StatelessWidget {
  const _LiturgyView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
            title: Text('liturgy.title'.tr()),
            actions: const [StageCastButton()],
          ),
      floatingActionButton: BlocBuilder<LiturgyBloc, LiturgyState>(
        builder: (context, state) {
          if (state is LiturgyLoaded && state.items.isNotEmpty) {
            return FloatingActionButton(
              onPressed: () => showLiturgyItemDialog(context,
                  isCategory: true),
              child: const Icon(TablerIcons.plus, size: 24),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: BlocBuilder<LiturgyBloc, LiturgyState>(
        builder: (context, state) {
          if (state is! LiturgyLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return _Body(state: state);
        },
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final LiturgyLoaded state;

  const _Body({required this.state});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _stopwatch = Stopwatch();
  Duration _elapsed = Duration.zero;
  final Set<String> _collapsedCategories = {};

  // Horario de inicio do culto (null = nao definido, usa stopwatch manual)
  TimeOfDay? _startTime;

  // Tick periodico para atualizar o display em tempo real
  Timer? _tickTimer;

  int get _totalDurationMs => widget.state.items
      .fold(0, (sum, item) => sum + item.durationMs);

  String _formatDuration(int ms) {
    final h = ms ~/ 3600000;
    final m = (ms % 3600000) ~/ 60000;
    final s = (ms % 60000) ~/ 1000;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Duration get _currentElapsed {
    if (_startTime != null) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day,
          _startTime!.hour, _startTime!.minute);
      final diff = now.difference(start);
      return diff.isNegative ? Duration.zero : diff;
    }
    return _stopwatch.isRunning ? _stopwatch.elapsed : _elapsed;
  }

  bool get _isRunning => _startTime != null || _stopwatch.isRunning;

  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopTick() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _startTime = picked;
        _stopwatch.stop();
        _elapsed = Duration.zero;
      });
      _startTick();
    }
  }

  void _toggleTimer() {
    setState(() {
      if (_startTime != null) {
        _startTime = null;
        _stopTick();
        return;
      }
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _elapsed = _stopwatch.elapsed;
        _stopTick();
      } else {
        _stopwatch.start();
        _startTick();
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _stopwatch.reset();
      _elapsed = Duration.zero;
      _startTime = null;
    });
    _stopTick();
  }

  void _toggleCollapse(String categoryId) {
    setState(() {
      if (_collapsedCategories.contains(categoryId)) {
        _collapsedCategories.remove(categoryId);
      } else {
        _collapsedCategories.add(categoryId);
      }
    });
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _stopTick();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _DayTabs(selectedDay: widget.state.selectedDay),
        // Cronometro de culto -- layout em 2 linhas
        if (widget.state.items.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.surfaceContainer,
            child: Column(
              children: [
                // Linha 1: horario de inicio + tempo decorrido + botoes
                Row(
                  children: [
                    // Horario de inicio clicavel
                    GestureDetector(
                      key: const Key('cult-start-time'),
                      onTap: () => _pickStartTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _startTime != null
                              ? theme.colorScheme.primary.withValues(alpha: 0.12)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(TablerIcons.calendarTime, size: 18,
                                color: _startTime != null
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(
                              _startTime != null
                                  ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                                  : 'liturgy.setStartTime'.tr(),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _startTime != null
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Display do tempo decorrido
                    Expanded(
                      child: Text(
                        _formatDuration(_currentElapsed.inMilliseconds),
                        key: const Key('cult-timer-display'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: _isRunning ? theme.colorScheme.primary : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botao play/pause/limpar
                    IconButton(
                      key: const Key('cult-timer-toggle'),
                      icon: Icon(
                        _startTime != null
                            ? TablerIcons.circleX
                            : (_stopwatch.isRunning ? TablerIcons.playerPauseFilled : TablerIcons.playerPlayFilled),
                        size: 24,
                      ),
                      color: theme.colorScheme.primary,
                      onPressed: _toggleTimer,
                    ),
                    if (_elapsed > Duration.zero || _stopwatch.elapsed > Duration.zero || _startTime != null)
                      IconButton(
                        key: const Key('cult-timer-reset'),
                        icon: const Icon(TablerIcons.refresh, size: 20),
                        onPressed: _resetTimer,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Linha 2: duracao total
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(TablerIcons.hourglass, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${'liturgy.totalDuration'.tr()}: ${_formatDuration(_totalDurationMs)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: widget.state.items.isEmpty
              ? _EmptyState()
              : _Timeline(
                  items: widget.state.items,
                  collapsedCategories: _collapsedCategories,
                  onToggleCollapse: _toggleCollapse,
                ),
        ),
        _NotesBar(notes: widget.state.notes),
      ],
    );
  }
}

// --- Day Tabs ---

class _DayTabs extends StatelessWidget {
  final LiturgyWeekday selectedDay;

  const _DayTabs({required this.selectedDay});

  String _label(LiturgyWeekday day) {
    const keys = {
      LiturgyWeekday.sunday: 'liturgy.days.sunday',
      LiturgyWeekday.monday: 'liturgy.days.monday',
      LiturgyWeekday.tuesday: 'liturgy.days.tuesday',
      LiturgyWeekday.wednesday: 'liturgy.days.wednesday',
      LiturgyWeekday.thursday: 'liturgy.days.thursday',
      LiturgyWeekday.friday: 'liturgy.days.friday',
      LiturgyWeekday.saturday: 'liturgy.days.saturday',
    };
    return keys[day]?.tr() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s1, vertical: AppSpacing.s2),
      child: Row(
        children: liturgyDayTabOrder.map((day) {
          final isSelected = day == selectedDay;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () {
                  context.read<LiturgyBloc>().add(LiturgyDayChanged(day));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _label(day),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// --- Timeline hierarquica ---

/// Segmento da timeline: ou uma categoria (com ou sem filhos) ou item avulso.
class _TimelineSegment {
  final LiturgyItem item;
  final int originalIndex;
  final List<_ChildEntry> children;

  _TimelineSegment({
    required this.item,
    required this.originalIndex,
    List<_ChildEntry>? children,
  }) : children = children ?? const [];
}

class _ChildEntry {
  final LiturgyItem item;
  final int originalIndex;

  const _ChildEntry({required this.item, required this.originalIndex});
}

List<_TimelineSegment> _buildSegments(List<LiturgyItem> items) {
  final segments = <_TimelineSegment>[];
  int i = 0;
  while (i < items.length) {
    final item = items[i];
    if (item.type == LiturgyItemType.category) {
      final catIndex = i;
      i++;
      final children = <_ChildEntry>[];
      while (i < items.length &&
          items[i].type != LiturgyItemType.category &&
          items[i].categoryId == item.id) {
        children.add(_ChildEntry(item: items[i], originalIndex: i));
        i++;
      }
      segments.add(_TimelineSegment(
          item: item, originalIndex: catIndex, children: children));
    } else {
      segments
          .add(_TimelineSegment(item: item, originalIndex: i, children: const []));
      i++;
    }
  }
  return segments;
}

class _Timeline extends StatelessWidget {
  final List<LiturgyItem> items;
  final Set<String> collapsedCategories;
  final ValueChanged<String> onToggleCollapse;

  const _Timeline({
    required this.items,
    required this.collapsedCategories,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segments = _buildSegments(items);

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.s3),
      itemCount: segments.length,
      itemBuilder: (context, segIndex) {
        final seg = segments[segIndex];
        final isCategory = seg.item.type == LiturgyItemType.category;
        final isCollapsed = isCategory && collapsedCategories.contains(seg.item.id);

        return Column(
          key: ValueKey(seg.item.id),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ItemCard(
              item: seg.item,
              isCategory: isCategory,
              theme: theme,
              hasChildren: seg.children.isNotEmpty,
              isCollapsed: isCollapsed,
              onToggleCollapse: isCategory && seg.children.isNotEmpty
                  ? () => onToggleCollapse(seg.item.id)
                  : null,
            ),
            // Filhos indentados (ocultos quando colapsados)
            if (!isCollapsed)
              for (final child in seg.children)
                Padding(
                  key: ValueKey(child.item.id),
                  padding: const EdgeInsets.only(left: 32, bottom: 4),
                  child: _ItemCard(
                    item: child.item,
                    isCategory: false,
                    theme: theme,
                    isChild: true,
                  ),
                ),
          ],
        );
      },
    );
  }
}

// --- Item Card ---

class _ItemCard extends StatelessWidget {
  /// Palco: projeta o item da liturgia em execução na TV (se ligado).
  Future<void> _projectToStage(LiturgyItem item) async {
    final stage = StageSession.instance;
    if (!stage.isOn) return;
    await stage.project(
      title: item.name,
      body: item.subtitle.isEmpty ? null : item.subtitle,
    );
  }
  final LiturgyItem item;
  final bool isCategory;
  final ThemeData theme;
  final bool isChild;
  final bool hasChildren;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const _ItemCard({
    required this.item,
    required this.isCategory,
    required this.theme,
    this.isChild = false,
    this.hasChildren = false,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final typeMeta = LiturgyTypeRegistry.metaFor(item.type);
    final accent = item.accentColor.isNotEmpty
        ? _parseHex(item.accentColor)
        : typeMeta.color;

    return Card(
      margin: EdgeInsets.only(
          bottom: isChild ? 2 : AppSpacing.s1,
          top: isChild ? 0 : 0),
      color: isCategory
          ? accent.withValues(alpha: 0.10)
          : isChild
              ? theme.colorScheme.surfaceContainerLow
              : theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
        side: isCategory
            ? BorderSide(color: accent.withValues(alpha: 0.4), width: 1)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: !isCategory && LiturgyItemExecutor.isExecutable(item.type)
            ? () async {
                _projectToStage(item);
                final msg = await LiturgyItemExecutor.execute(context, item);
                if (msg.isNotEmpty && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
                  );
                }
              }
            : null,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s3, vertical: AppSpacing.s1),
        leading: Container(
          width: isChild ? 28 : 36,
          height: isChild ? 28 : 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
          ),
          child: Icon(typeMeta.icon,
              size: isChild ? 16 : 20, color: accent),
        ),
        title: Text(
          item.name.isEmpty
              ? 'liturgy.types.${_typeToKey(item.type)}'.tr()
              : item.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isCategory ? FontWeight.w700 : FontWeight.w500,
            fontSize: isChild ? 14 : null,
            decoration: item.done ? TextDecoration.lineThrough : null,
            color: item.done ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: item.subtitle.isNotEmpty
            ? Text(item.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: isChild ? 12 : null,
                ))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCategory && hasChildren && onToggleCollapse != null)
              IconButton(
                icon: Icon(
                  isCollapsed ? TablerIcons.chevronRight : TablerIcons.chevronDown,
                  size: 20,
                ),
                tooltip: isCollapsed ? 'liturgy.actions.expand'.tr() : 'liturgy.actions.collapse'.tr(),
                onPressed: onToggleCollapse,
              ),
            if (isCategory)
              IconButton(
                icon: const Icon(TablerIcons.plus, size: 20),
                tooltip: 'liturgy.actions.addSubItem'.tr(),
                onPressed: () => showLiturgyItemDialog(
                  context,
                  parentCategoryId: item.id,
                ),
              ),
            if (item.durationMs > 0)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s1),
                child: Text(
                  '${item.durationMs ~/ 60000}${'liturgy.durationMin'.tr()}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            GestureDetector(
              onTap: () {
                context.read<LiturgyBloc>().add(LiturgyToggleDone(item.id));
              },
              child: Icon(
                item.done ? TablerIcons.circleCheck : TablerIcons.circle,
                size: 22,
                color: item.done
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(TablerIcons.dotsVertical, size: 20),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    const Icon(TablerIcons.pencil, size: 18),
                    const SizedBox(width: 8),
                    Text('liturgy.actions.edit'.tr()),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(TablerIcons.trash, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('liturgy.actions.delete'.tr()),
                  ]),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  showLiturgyItemDialog(context, existing: item);
                } else if (value == 'delete') {
                  context.read<LiturgyBloc>().add(LiturgyDeleteItem(item.id));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _parseHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return theme.colorScheme.primary;
  }
}

// --- Empty State ---

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.clipboardList,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.s4),
            Text('liturgy.emptyList'.tr(),
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.s4),
            FilledButton.icon(
              onPressed: () => showLiturgyItemDialog(context, isCategory: true),
              icon: const Icon(TablerIcons.plus, size: 18),
              label: Text('liturgy.addItem'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Notes Bar ---

class _NotesBar extends StatelessWidget {
  final String notes;

  const _NotesBar({required this.notes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'liturgy.notesPlaceholder'.tr(),
          prefixIcon: const Icon(TablerIcons.notes, size: 20),
          isDense: true,
          border: InputBorder.none,
        ),
        style: theme.textTheme.bodySmall,
        controller: TextEditingController(text: notes),
        onChanged: (v) {
          context.read<LiturgyBloc>().add(LiturgyUpdateNotes(v));
        },
      ),
    );
  }
}

// --- Dialog de criar/editar item ---

