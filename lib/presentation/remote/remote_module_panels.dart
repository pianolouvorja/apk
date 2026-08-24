// coverage:ignore-file
// UI dos módulos v2 do controle remoto (bible/timer/countdown) — widget
// tree pura sobre RemoteSession.send, sem lógica testável isolada.
library;

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import 'package:louvorja_piano_mobile/app/theme/app_spacing.dart';
import 'package:louvorja_piano_mobile/core/services/remote/remote_protocol.dart';
import 'package:louvorja_piano_mobile/core/services/remote/remote_session.dart';
import 'package:louvorja_piano_mobile/domain/entities/hymn.dart';
import 'package:louvorja_piano_mobile/data/repositories/hymn_repository_impl.dart';
import 'package:louvorja_piano_mobile/data/datasources/remote/louvorja_api_impl.dart';
import 'package:louvorja_piano_mobile/data/datasources/local/catalog_cache.dart';

typedef RemoteSend = Future<void> Function(
  RemoteAction action, {
  int? index,
  int? volume,
  int? versionId,
  int? bookId,
  int? chapter,
  int? verse,
  int? durationMs,
  String? name,
  String? style,
  bool? showSeconds,
  bool? format24h,
  int? musicId,
  String? mode,
});

RemoteSend _defaultSend = (action,
    {index, volume, versionId, bookId, chapter, verse, durationMs, name, style, showSeconds, format24h, musicId, mode}) {
  return RemoteSession.instance.send(
    RemoteCommand(
      id: 'm${DateTime.now().microsecondsSinceEpoch}',
      action: action,
      index: index,
      volume: volume,
      versionId: versionId,
      bookId: bookId,
      chapter: chapter,
      verse: verse,
      durationMs: durationMs,
      name: name,
      style: style,
      showSeconds: showSeconds,
      format24h: format24h,
      musicId: musicId,
      mode: mode,
    ),
  );
};

/// Painel Bíblia: livro/capítulo/versículo numéricos + abrir/projetar.
///
/// v2 fase 1: entrada numérica direta (livro por número). A grade visual
/// de livros (com nomes) entra com a integração do catálogo local.
class RemoteBiblePanel extends StatefulWidget {
  const RemoteBiblePanel({super.key, this.send});

  final RemoteSend? send;

  @override
  State<RemoteBiblePanel> createState() => _RemoteBiblePanelState();
}

class _RemoteBiblePanelState extends State<RemoteBiblePanel> {
  final _bookCtrl = TextEditingController();
  final _chapterCtrl = TextEditingController(text: '1');
  final _verseCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _bookCtrl.dispose();
    _chapterCtrl.dispose();
    _verseCtrl.dispose();
    super.dispose();
  }

  int? _parse(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return (v != null && v >= 1) ? v : null;
  }

  Future<void> _open() async {
    final book = _parse(_bookCtrl);
    final chapter = _parse(_chapterCtrl);
    final verse = _parse(_verseCtrl);
    if (book == null || chapter == null) return;
    await (widget.send ?? _defaultSend)(
      RemoteAction.bibleOpen,
      bookId: book,
      chapter: chapter,
      verse: verse,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        Text('remote.bible.hint'.tr(), style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.s3),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('remote-bible-book'),
                controller: _bookCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'remote.bible.book'.tr(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: TextField(
                key: const Key('remote-bible-chapter'),
                controller: _chapterCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'remote.bible.chapter'.tr(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: TextField(
                key: const Key('remote-bible-verse'),
                controller: _verseCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'remote.bible.verse'.tr(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        FilledButton.icon(
          key: const Key('remote-bible-open'),
          onPressed: _open,
          icon: const Icon(TablerIcons.book),
          label: Text('remote.bible.open'.tr()),
        ),
        const SizedBox(height: AppSpacing.s2),
        OutlinedButton.icon(
          onPressed: () =>
              (widget.send ?? _defaultSend)(RemoteAction.bibleClose),
          icon: const Icon(TablerIcons.squareX),
          label: Text('remote.bible.close'.tr()),
        ),
      ],
    );
  }
}

/// Painel Tempo: timer + countdown lado a lado, espelhando o estado v2.
class RemoteTimePanel extends StatelessWidget {
  const RemoteTimePanel({super.key, this.send, this.state});

  final RemoteSend? send;
  final RemotePlayerState? state;

  RemoteSend get _send => send ?? _defaultSend;

  @override
  Widget build(BuildContext context) {
    final timer = state?.timerModule;
    final countdown = state?.countdownModule;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        _TimeCard(
          key: const Key('remote-timer-card'),
          title: 'remote.timer.title'.tr(),
          status: timer?.status,
          elapsedMs: timer?.accumulatedMs ?? 0,
          marks: timer?.savedTimesMs ?? const [],
          onStart: () => _send(RemoteAction.timerStart),
          onPause: () => _send(RemoteAction.timerPause),
          onReset: () => _send(RemoteAction.timerReset),
          onSaveMark: () => _send(RemoteAction.timerSaveMark),
        ),
        const SizedBox(height: AppSpacing.s4),
        _TimeCard(
          key: const Key('remote-countdown-card'),
          title: 'remote.countdown.title'.tr(),
          status: countdown?.status,
          elapsedMs: countdown?.accumulatedMs ?? 0,
          totalMs: countdown?.durationMs,
          marks: countdown?.savedTimesMs ?? const [],
          finished: countdown?.finished ?? false,
          tag: 'countdown',
          onStart: () => _send(RemoteAction.countdownStart),
          onPause: () => _send(RemoteAction.countdownPause),
          onReset: () => _send(RemoteAction.countdownReset),
          onSaveMark: () => _send(RemoteAction.countdownSaveMark),
        ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    super.key,
    required this.title,
    required this.status,
    required this.elapsedMs,
    required this.marks,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.onSaveMark,
    this.totalMs,
    this.finished = false,
    this.tag = 'timer',
  });

  final String title;
  final String? status;

  final int elapsedMs;
  final int? totalMs;
  final List<int> marks;
  final bool finished;
  final String tag; // sufixo de key (timer/countdown)
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onSaveMark;

  String _fmt(int ms) {
    final total = ms ~/ 1000;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final running = status == 'running';
    final remaining =
        totalMs != null ? (totalMs! - elapsedMs).clamp(0, totalMs!) : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                if (finished)
                  Icon(TablerIcons.alertCircle, color: theme.colorScheme.error),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              remaining != null ? _fmt(remaining) : _fmt(elapsedMs),
              style: theme.textTheme.displaySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (marks.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(
                '${'remote.marks'.tr()}: ${marks.map(_fmt).join(' · ')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.s3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filled(
                  key: Key('remote-$tag-toggle'),
                  tooltip: running
                      ? 'remote.pause'.tr()
                      : 'remote.play'.tr(),
                  onPressed: running ? onPause : onStart,
                  icon: Icon(
                    running ? TablerIcons.playerPause : TablerIcons.playerPlay,
                  ),
                ),
                IconButton(
                  tooltip: 'remote.mark'.tr(),
                  onPressed: onSaveMark,
                  icon: const Icon(TablerIcons.flag),
                ),
                IconButton(
                  tooltip: 'remote.reset'.tr(),
                  onPressed: onReset,
                  icon: const Icon(TablerIcons.rotate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class RemoteClockRandomPanel extends StatelessWidget {
  const RemoteClockRandomPanel({super.key, this.send, this.clock, this.random});
  final RemoteSend? send;
  final RemoteClockState? clock;
  final RemoteRandomState? random;
  RemoteSend get _send => send ?? _defaultSend;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.s4),
    children: [
      Card(child: ListTile(
        leading: const Icon(TablerIcons.clock),
        title: Text('remote.clock.title'.tr()),
        subtitle: Text(clock == null ? '—' : '${clock!.style} · ${clock!.format24h ? '24h' : '12h'}'),
        trailing: FilledButton(
          onPressed: () => _send(RemoteAction.clockToggleProjection),
          child: Text('remote.project'.tr()),
        ),
      )),
      Card(child: ListTile(
        leading: const Icon(TablerIcons.dice),
        title: Text('remote.random.title'.tr()),
        subtitle: Text(random == null ? '—' : '${random!.drawnCount} / ${random!.availableCount}'),
        trailing: FilledButton(
          onPressed: () => _send(RemoteAction.randomStartDraw),
          child: Text('remote.draw'.tr()),
        ),
      )),
      OutlinedButton.icon(
        onPressed: () => _send(RemoteAction.randomCancelDraw),
        icon: const Icon(TablerIcons.playerStop),
        label: Text('remote.stop'.tr()),
      ),
    ],
  );
}


/// Painel Hinos (fase 3): busca no catálogo local → abre no desktop.
///
/// O catálogo (HymnRepository) é offline-first; o resultado escolhido
/// vira media.open {musicId, mode} no alvo conectado.
class RemoteHymnsPanel extends StatefulWidget {
  const RemoteHymnsPanel({super.key, this.send, this.repository});

  final RemoteSend? send;
  final Future<List<Hymn>> Function(String query)? repository;

  @override
  State<RemoteHymnsPanel> createState() => _RemoteHymnsPanelState();
}

class _RemoteHymnsPanelState extends State<RemoteHymnsPanel> {
  final _queryCtrl = TextEditingController();
  Timer? _debounce;
  List<Hymn> _results = const [];
  bool _loading = false;
  String _mode = 'audio';

  static const _modes = [('audio', 'Cantado'), ('instrumental', 'Playback'), ('no_audio', 'Só slides')];

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<List<Hymn>> _search(String q) async {
    if (widget.repository != null) return widget.repository!(q);
    try {
      await null; // permite await uniforme no fallback
      final api = LouvorjaApiImpl(
        baseUrl: 'https://api.louvorja.com.br/json_db',
        filesUrl: 'https://api.louvorja.com.br/file',
        apiToken: const String.fromEnvironment('API_TOKEN', defaultValue: ''),
        languagePrefix: 'pt',
      );
      return await HymnRepositoryImpl(
        api,
        CatalogCache.noop(),
      ).searchHymns(q);
    } catch (_) {
      return const [];
    }
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _search(q.trim());
      if (mounted) setState(() { _results = results; _loading = false; });
    });
  }

  void _open(Hymn hymn) =>
      (widget.send ?? _defaultSend)(
        RemoteAction.mediaOpen,
        musicId: hymn.id,
        mode: _mode,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: TextField(
            key: const Key('remote-hymns-query'),
            controller: _queryCtrl,
            onChanged: _onQuery,
            decoration: InputDecoration(
              prefixIcon: const Icon(TablerIcons.search),
              labelText: 'remote.hymns.search'.tr(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          child: Wrap(
            spacing: AppSpacing.s2,
            children: [
              for (final (m, label) in _modes)
                ChoiceChip(
                  key: Key('remote-hymns-mode-$m'),
                  label: Text(label),
                  selected: _mode == m,
                  onSelected: (_) => setState(() => _mode = m),
                ),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: _results.isEmpty
              ? Center(child: Text('remote.hymns.empty'.tr(), style: theme.textTheme.bodySmall))
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final h = _results[i];
                    return ListTile(
                      key: Key('remote-hymns-result-$i'),
                      dense: true,
                      title: Text('${h.number ?? h.id} — ${h.title ?? ''}'),
                      onTap: () => _open(h),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
