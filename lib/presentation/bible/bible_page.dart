// coverage:ignore-file
// UI de Biblia -- nao testavel em unit tests (depende de BLoC + widget tree)
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import 'package:louvorja_piano_mobile/app/theme/app_spacing.dart';
import 'package:louvorja_piano_mobile/data/datasources/local/catalog_cache.dart';
import 'package:louvorja_piano_mobile/data/datasources/remote/louvorja_api_impl.dart';
import 'package:louvorja_piano_mobile/data/repositories/bible_repository_impl.dart';
import 'package:louvorja_piano_mobile/app/theme/app_radius.dart';
import 'package:louvorja_piano_mobile/core/services/global_search_service.dart';
import 'package:louvorja_piano_mobile/domain/entities/bible_book.dart';
import 'package:louvorja_piano_mobile/core/services/bible_offline_versions.dart';
import 'package:louvorja_piano_mobile/presentation/bible/book_colors.dart';
import 'package:louvorja_piano_mobile/presentation/bible/bible_download_button.dart';
import 'package:louvorja_piano_mobile/presentation/shared/widgets/stage_cast_button.dart';
import 'package:louvorja_piano_mobile/presentation/shared/widgets/stage_stop_video_button.dart';
import 'package:louvorja_piano_mobile/core/services/dlna/stage_session.dart';
import 'package:louvorja_piano_mobile/presentation/bible/bloc/bible_bloc.dart';

class BiblePage extends StatelessWidget {
  final BibleBloc? testBloc;

  const BiblePage({super.key, this.testBloc});

  @override
  Widget build(BuildContext context) {
    if (testBloc != null) {
      return BlocProvider<BibleBloc>.value(
        value: testBloc!,
        child: const _BibleView(),
      );
    }
    // coverage:ignore-start
    final api = LouvorjaApiImpl(
      baseUrl: 'https://api.louvorja.com.br/json_db',
      filesUrl: 'https://api.louvorja.com.br/file',
      apiToken: const String.fromEnvironment('API_TOKEN', defaultValue: ''),
      // API possui catálogo espanhol; EN faz fallback para catálogo PT.
      languagePrefix: context.locale.languageCode == 'es' ? 'es' : 'pt',
    );
    final bloc = BibleBloc(BibleRepositoryImpl(api, CatalogCache.noop()))
      ..add(BibleBootstrap());
    return BlocProvider<BibleBloc>.value(
      value: bloc,
      child: const _BibleView(),
    );
    // coverage:ignore-end
  }
}

/// Painel que pode estar expandido ou colapsado.
enum NavPanel { books, chapters, verses }

class _BibleView extends StatefulWidget {
  const _BibleView();

  @override
  State<_BibleView> createState() => _BibleViewState();
}

class _BibleViewState extends State<_BibleView> {
  /// Qual painel de navegacao esta aberto.
  /// Books: usuario escolhendo livro.
  /// Chapters: livro selecionado, escolhendo capitulo.
  /// Verses: capitulo selecionado, lendo versiculos.
  NavPanel _activePanel = NavPanel.books;

  void _onBookSelected(BuildContext context, int bookId) {
    context.read<BibleBloc>().add(BibleSelectBook(bookId));
    setState(() => _activePanel = NavPanel.chapters);
  }

  void _onChapterSelected(BuildContext context, int chapter) {
    context.read<BibleBloc>().add(BibleSelectChapter(chapter));
    setState(() => _activePanel = NavPanel.verses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('bible.title'.tr()),
        actions: const [
          StageClearButton(),
          StageStopVideoButton(),
          StageCastButton(),
          BibleDownloadButton(),
        ],
      ),
      body: BlocBuilder<BibleBloc, BibleState>(
        builder: (context, state) {
          if (state is BibleLoading || state is BibleInitial) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.s3),
                  Text('bible.loading'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }
          if (state is BibleError) {
            return _ErrorView(code: state.code);
          }
          if (state is BibleLoaded) {
            return _body(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _body(BuildContext context, BibleLoaded state) {
    final theme = Theme.of(context);
    final book = state.selectedBook;
    final hasBook = book != null;
    final hasChapter = state.verses.isNotEmpty;

    return Column(
      children: [
        // Toolbar
        _Toolbar(state: state),

        // Painel de Livros (expansivel/colapsavel)
        _CollapsibleSection(
          title: 'bible.books'.tr(),
          subtitle: hasBook ? book.name : null,
          icon: TablerIcons.books,
          isExpanded: _activePanel == NavPanel.books,
          onTap: () => setState(
              () => _activePanel = NavPanel.books),
          child: _BookGrid(
            state: state,
            theme: theme,
            onBookSelected: (id) => _onBookSelected(context, id),
          ),
        ),

        // Painel de Capitulos (so aparece quando livro selecionado)
        if (hasBook)
          _CollapsibleSection(
            title: 'bible.chapters'.tr(),
            subtitle: hasChapter
                ? '${state.selectedChapter}'
                : null,
            icon: TablerIcons.listNumbers,
            isExpanded: _activePanel == NavPanel.chapters,
            onTap: () => setState(
                () => _activePanel = NavPanel.chapters),
            child: _ChapterGridSection(
              state: state,
              theme: theme,
              onChapterSelected: (c) => _onChapterSelected(context, c),
            ),
          ),

        // Versiculos (so aparece quando capitulo carregado)
        if (hasChapter)
          Expanded(
            child: _VerseList(state: state, theme: theme),
          ),

        // Espacador quando versiculos vazios e nenhum painel expandido
        if (!hasChapter) const Spacer(),
      ],
    );
  }
}

// --- Collapsible Section ---

class _CollapsibleSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.isExpanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Header clicavel
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
            decoration: BoxDecoration(
              color: isExpanded
                  ? theme.colorScheme.surfaceContainer
                  : theme.colorScheme.surface,
              border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.s2),
                Text(title.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.primary)),
                if (subtitle != null) ...[
                  const SizedBox(width: AppSpacing.s2),
                  Text(subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
                const Spacer(),
                Icon(
                  isExpanded
                      ? TablerIcons.chevronUp
                      : TablerIcons.chevronDown,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        // Conteudo expansivel
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: child,
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// --- Toolbar ---

class _Toolbar extends StatelessWidget {
  final BibleLoaded state;

  const _Toolbar({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final versionLanguage = context.locale.languageCode == 'es' ? 'es' : 'pt';
    final langVersions = state.versions
        .where((version) => version.languageId == versionLanguage)
        .toList();
    // Offline: só versões com download completo no disco (marcadas pelo
    // BibleDownloadButton). Pedido Rafael 2026-08-16.
    final visibleVersions = BibleOfflineVersions.filter(langVersions);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // Versao (compacto: so abreviacao)
          DropdownButton<int>(
            value: state.selectedVersionId,
            underline: const SizedBox(),
            isDense: true,
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            items: visibleVersions
                .map((v) => DropdownMenuItem(
                      value: v.id,
                      child: Text(v.abbreviation,
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ))
                .toList(),
            onChanged: (id) {
              if (id != null) {
                context.read<BibleBloc>().add(BibleSelectVersion(id));
              }
            },
          ),
          Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
              color: theme.colorScheme.outline),
          // Localizacao
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('bible.location'.tr().toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.6,
                        color: theme.colorScheme.onSurfaceVariant)),
                Text(
                  state.locationLabel,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Book Grid ---

class _BookGrid extends StatefulWidget {
  final BibleLoaded state;
  final ThemeData theme;
  final ValueChanged<int> onBookSelected;

  const _BookGrid({
    required this.state,
    required this.theme,
    required this.onBookSelected,
  });

  @override
  State<_BookGrid> createState() => _BookGridState();
}

class _BookGridState extends State<_BookGrid> {
  bool _showNt = false;

  @override
  Widget build(BuildContext context) {
    final allBooks = widget.state.books;
    final otBooks =
        allBooks.where((b) => b.testament == BibleTestament.ot).toList();
    final ntBooks =
        allBooks.where((b) => b.testament == BibleTestament.nt).toList();

    // Se o livro selecionado e do NT, mostra NT por padrao
    final selectedIsNt = widget.state.selectedBook?.testament == BibleTestament.nt;
    final effectiveShowNt = _showNt || (selectedIsNt && !_userToggled);
    final view = effectiveShowNt ? ntBooks : otBooks;

    return SizedBox(
      height: 320,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s3),
        children: [
          // Tabs AT/NT
          Row(
            children: [
              _TabButton(
                label: 'bible.testamentOld'.tr(),
                active: !effectiveShowNt,
                onTap: () => setState(() { _showNt = false; _userToggled = true; }),
                theme: widget.theme,
              ),
              const SizedBox(width: 4),
              _TabButton(
                label: 'bible.testamentNew'.tr(),
                active: effectiveShowNt,
                onTap: () => setState(() { _showNt = true; _userToggled = true; }),
                theme: widget.theme,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          // Grid de livros
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: view.length,
            itemBuilder: (context, index) {
              final book = view[index];
              return _BookTile(
                book: book,
                isSelected: book.id == widget.state.selectedBookId,
                theme: widget.theme,
                onTap: () => widget.onBookSelected(book.id),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _userToggled = false;
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final ThemeData theme;

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = theme.brightness == Brightness.light;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primary
              : isLight
                  ? theme.colorScheme.surfaceContainerHigh
                  : null,
          border: active ? null : Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
        ),
        child: Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: active
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            )),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final BibleBook book;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _BookTile({
    required this.book,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  Color get _toneColor => BookColors.tone(book, theme, selected: isSelected);

  Color get _bgColor =>
      BookColors.background(book, theme, selected: isSelected);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _bgColor,
          border: isSelected
              ? Border.all(color: const Color(0xFFEAB308))
              : Border.all(color: Colors.transparent),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(book.abbreviation,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _toneColor,
                )),
            const SizedBox(height: 2),
            Text(book.name,
                style: TextStyle(fontSize: 8, color: _toneColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// --- Chapter Grid ---

class _ChapterGridSection extends StatelessWidget {
  final BibleLoaded state;
  final ThemeData theme;
  final ValueChanged<int> onChapterSelected;

  const _ChapterGridSection({
    required this.state,
    required this.theme,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final book = state.selectedBook;
    if (book == null) return const SizedBox.shrink();

    return SizedBox(
      height: 240,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.s3),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          childAspectRatio: 1,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: book.chapters,
        itemBuilder: (context, index) {
          final chapter = index + 1;
          final isSelected = chapter == state.selectedChapter;
          final isLight = theme.brightness == Brightness.light;
          return GestureDetector(
            onTap: () => onChapterSelected(chapter),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.tertiaryContainer
                    : isLight
                        ? theme.colorScheme.surfaceContainerHigh
                        : theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8)),
                border: isSelected
                    ? Border.all(color: theme.colorScheme.tertiary, width: 1.5)
                    : Border.all(
                        color: isLight
                            ? theme.colorScheme.outline
                            : theme.colorScheme.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Text(
                '$chapter',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.onTertiaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Verse List ---

class _VerseList extends StatefulWidget {
  final BibleLoaded state;
  final ThemeData theme;

  const _VerseList({required this.state, required this.theme});

  @override
  State<_VerseList> createState() => _VerseListState();
}

class _VerseListState extends State<_VerseList> {
  /// Palco: projeta os versículos selecionados na TV (se ligado).
  Future<void> _projectSelectedVerses(BibleLoaded state, int toggledVerse) async {
    final stage = StageSession.instance;
    if (!stage.isOn) return;
    final selected = [...state.selectedVerses]..sort();
    final versesToShow = selected.contains(toggledVerse)
        ? selected
        : [toggledVerse];
    final text = versesToShow
        .map((n) => state.verses[n.toString()] ?? '')
        .join(' ');
    final book = state.books
        .where((b) => b.id == state.selectedBookId)
        .firstOrNull;
    // F3.3m: referência destacada (cor/ peso próprios) + versão ao lado.
    final version = state.versions
        .where((v) => v.id == state.selectedVersionId)
        .firstOrNull;
    await stage.project(
      title: text,
      footer:
          '${book?.name ?? ''} ${state.selectedChapter}:${versesToShow.join('-')}',
      footerRef:
          '${book?.name ?? ''} ${state.selectedChapter}:${versesToShow.join('-')}',
      footerVersion: version?.abbreviation,
      isBible: true, // F3.3o: tipografia própria da Bíblia
    );
  }
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = widget.theme;
    final book = state.selectedBook;
    final title = book != null
        ? '${book.name} ${state.selectedChapter}'
        : 'bible.title'.tr();

    // Busca local com normalizacao de acentos (mesma logica da global).
    final visibleVerses = _searchQuery.isEmpty
        ? state.verses
        : GlobalSearchService.filterVerses(state.verses, _searchQuery);

    final entries = visibleVerses.entries
        .map((e) => MapEntry(int.tryParse(e.key) ?? 0, e.value))
        .where((e) => e.key > 0)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
          child: Row(
            children: [
              Expanded(
                child: Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (state.selectedVerses.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(TablerIcons.chevronLeft, size: 20),
                  onPressed: () => context
                      .read<BibleBloc>()
                      .add(const BibleNavigateVerse(-1)),
                  tooltip: 'bible.previousVerse'.tr(),
                ),
                IconButton(
                  icon: const Icon(TablerIcons.chevronRight, size: 20),
                  onPressed: () => context
                      .read<BibleBloc>()
                      .add(const BibleNavigateVerse(1)),
                  tooltip: 'bible.nextVerse'.tr(),
                ),
                IconButton(
                  icon: const Icon(TablerIcons.x, size: 18),
                  onPressed: () =>
                      context.read<BibleBloc>().add(BibleClearSelection()),
                  tooltip: 'bible.clearSelection'.tr(),
                ),
              ],
            ],
          ),
        ),
        // Busca no capitulo (numero ou texto, com normalizacao)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'search.placeholder'.tr(),
              prefixIcon: const Icon(TablerIcons.search, size: 18),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: AppRadius.sm,
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        // Versiculos
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text('bible.emptyChapter'.tr(),
                      style: theme.textTheme.bodyMedium))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final verseNum = entries[index].key;
                    final verseText = entries[index].value;
                    final isSelected =
                        state.selectedVerses.contains(verseNum);

                    return GestureDetector(
                      onTap: () {
                        context.read<BibleBloc>()
                            .add(BibleSelectVerse(verseNum));
                        _projectSelectedVerses(state, verseNum);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.s2,
                            horizontal: AppSpacing.s3),
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.12)
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              width: 4,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4)),
                        ),
                        child: Opacity(
                          opacity: isSelected ? 1.0 : 0.65,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text('$verseNum',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: theme
                                                .colorScheme.primary)),
                              ),
                              const SizedBox(width: AppSpacing.s2),
                              Expanded(
                                child: Text(
                                  verseText,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                    height: 1.7,
                                    fontSize: isSelected ? 16 : 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w500
                                        : null,
                                    color: isSelected
                                        ? theme.colorScheme.onSurface
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// --- Error ---

class _ErrorView extends StatelessWidget {
  final String code;

  const _ErrorView({required this.code});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.alertCircle,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.s4),
            Text(code.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.s4),
            FilledButton.icon(
              onPressed: () =>
                  context.read<BibleBloc>().add(BibleBootstrap()),
              icon: const Icon(TablerIcons.refresh, size: 18),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

