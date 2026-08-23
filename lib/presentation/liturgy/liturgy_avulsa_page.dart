// Liturgia Avulsa: liturgia de uma data específica (não recorrente semanal).
// Usa storage próprio (liturgy_avulsa_yyyyMMdd) — não afeta a liturgia semanal.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import 'package:louvorja_piano_mobile/app/theme/app_spacing.dart';
import 'package:louvorja_piano_mobile/data/repositories/liturgy_repository.dart';
import 'package:louvorja_piano_mobile/domain/entities/liturgy_item.dart';
import 'package:louvorja_piano_mobile/presentation/liturgy/services/liturgy_item_executor.dart';
import 'package:louvorja_piano_mobile/presentation/liturgy/widgets/liturgy_item_dialog.dart';

class LiturgyAvulsaPage extends StatefulWidget {
  const LiturgyAvulsaPage({super.key});

  @override
  State<LiturgyAvulsaPage> createState() => _LiturgyAvulsaPageState();
}

class _LiturgyAvulsaPageState extends State<LiturgyAvulsaPage> {
  LiturgyRepository? _repo;
  DateTime _date = DateTime.now();
  List<LiturgyItem> _items = [];
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _repo = LiturgyRepository(prefs);
    _load();
  }

  void _load() {
    if (_repo == null) return;
    setState(() {
      _items = _repo!.loadAvulsa(_date);
      _locked = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
      _load();
    }
  }

  Future<void> _persist() async {
    await _repo?.saveAvulsa(_date, _items);
  }

  String get _dateLabel {
    final d = _date;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('liturgy.avulsa.title'.tr()),
        actions: [
          IconButton(
            key: const Key('avulsa-lock-toggle'),
            tooltip: _locked ? 'liturgy.unlock'.tr() : 'liturgy.lock'.tr(),
            icon: Icon(
              _locked ? TablerIcons.lock : TablerIcons.lockOpen,
              size: 22,
              color: _locked ? theme.colorScheme.primary : null,
            ),
            onPressed: () => setState(() => _locked = !_locked),
          ),
          IconButton(
            key: const Key('avulsa-delete'),
            tooltip: 'liturgy.deleteDay'.tr(),
            icon: const Icon(TablerIcons.trash, size: 22),
            onPressed: _items.isEmpty || _locked
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('liturgy.deleteDayTitle'.tr()),
                        content: Text('liturgy.avulsa.deleteConfirm'.tr()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('common.cancel'.tr()),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('liturgy.deleteDay'.tr()),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && mounted) {
                      await _repo?.clearAvulsa(_date);
                      _load();
                    }
                  },
          ),
        ],
      ),
      floatingActionButton: _locked
          ? null
          : FloatingActionButton(
              key: const Key('avulsa-add-item'),
              onPressed: _items.isEmpty
                  ? () => showLiturgyItemDialog(
                        context,
                        isCategory: true,
                        onSubmit: (item) {
                          setState(() => _items = [..._items, item]);
                          _persist();
                        },
                      )
                  : null,
              child: const Icon(TablerIcons.plus, size: 24),
            ),
      body: _repo == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Seletor de data
                InkWell(
                  key: const Key('avulsa-date-picker'),
                  onTap: _pickDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s4,
                      vertical: AppSpacing.s3,
                    ),
                    color: theme.colorScheme.surfaceContainer,
                    child: Row(
                      children: [
                        Icon(
                          TablerIcons.calendar,
                          size: 22,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.s3),
                        Text(
                          _dateLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'liturgy.avulsa.changeDate'.tr(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Text('liturgy.avulsa.empty'.tr()),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.s3),
                          buildDefaultDragHandles: false,
                          itemCount: _items.length,
                          onReorder: _locked
                              ? (_, __) {}
                              : (oldIndex, newIndex) async {
                                  final adjusted = newIndex > oldIndex
                                      ? newIndex - 1
                                      : newIndex;
                                  setState(() {
                                    final it = _items.removeAt(oldIndex);
                                    _items.insert(
                                      adjusted.clamp(0, _items.length),
                                      it,
                                    );
                                  });
                                  await _persist();
                                },
                          itemBuilder: (context, i) {
                            final item = _items[i];
                            return Card(
                              key: ValueKey('avulsa-${item.id}'),
                              margin:
                                  const EdgeInsets.only(bottom: AppSpacing.s1),
                              child: ListTile(
                                title: Text(item.name.isEmpty
                                    ? item.type.name
                                    : item.name),
                                subtitle: item.subtitle.isEmpty
                                    ? null
                                    : Text(item.subtitle),
                                onTap: !_locked &&
                                        LiturgyItemExecutor.isExecutable(
                                            item.type)
                                    ? () => LiturgyItemExecutor.execute(
                                        context, item)
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!_locked)
                                      ReorderableDragStartListener(
                                        index: i,
                                        child: Icon(
                                          TablerIcons.gripVertical,
                                          size: 18,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    GestureDetector(
                                      onTap: _locked
                                          ? null
                                          : () => setState(() {
                                                _items = _items
                                                    .map((e) =>
                                                        e.id == item.id
                                                            ? e.copyWith(
                                                                done: !e.done)
                                                            : e)
                                                    .toList();
                                                _persist();
                                              }),
                                      child: Icon(
                                        item.done
                                            ? TablerIcons.circleCheck
                                            : TablerIcons.circle,
                                        size: 22,
                                        color: item.done
                                            ? theme.colorScheme.primary
                                            : theme
                                                .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (!_locked)
                                      IconButton(
                                        icon: const Icon(
                                          TablerIcons.dotsVertical,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            showLiturgyItemDialog(
                                          context,
                                          existing: item,
                                          onSubmit: (updated) {
                                            setState(() {
                                              _items = _items
                                                  .map((e) =>
                                                      e.id == updated.id
                                                          ? updated
                                                          : e)
                                                  .toList();
                                            });
                                            _persist();
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
