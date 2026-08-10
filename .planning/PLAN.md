# PLAN — LouvorJA PIANO Flutter

> **SPEC:** [SPEC.md](./SPEC.md) (rev 2 — 2026-08-10)
> **CONTEXT:** [CONTEXT.md](./CONTEXT.md)
> **API:** [API.md](./API.md)
> **Criado:** 2026-08-01
> **Updated:** 2026-08-10 — Alinhado com análise modular do Electron
> **Metodologia:** Spec-Driven Development (tasks → changesets → design-decisions)

---

## Fase 0: Setup do Projeto ✓

### Task 0.1: Criar repositório e estrutura inicial ✓
- flutter create executado, plataformas web+linux+android
- flutter analyze 0 issues, flutter test pass, flutter build web OK

### Task 0.2: Configurar estrutura Clean Architecture ✓
- Pastas lib/{app,core,data,domain,presentation} criadas
- pubspec.yaml com dependências (flutter_bloc, dio, go_router, tabler_icons_plus, freezed, etc)

### Task 0.3: Configurar CI (GitHub Actions)
**Arquivo:** `.github/workflows/ci.yml`
**Jobs:** analyze (--fatal-infos) + test (--coverage) + build apk --debug
**Verificação:**
- [ ] CI roda em push para main e PRs
- [ ] Job de analyze falha se houver warnings

---

## Fase 1: Fundação + Design System + Navegação (3 semanas)

### Task 1.0: Design tokens extraídos do Electron
**Arquivos:**
- `lib/app/theme/app_colors.dart` — paleta completa (colors.ts)
- `lib/app/theme/app_spacing.dart` — grade 8px (spacing.ts)
- `lib/app/theme/app_radius.dart` — assimetria TL+BR (radius.ts)
- `lib/app/theme/app_blur.dart` — tokens de glass (blur.ts)
- `lib/app/theme/app_animations.dart` — perfis dynamic/soft/mist (page.ts)

**Fonte:** `pianolouvorja/app/src/design-system/tokens/`

**Verificação:**
- [ ] Cores batem com colors.ts (dark: #131313, light: #f8f9ff)
- [ ] BorderRadius.only(topLeft + bottomRight) em todos os raios
- [ ] Testes unitários verificando valores hex

### Task 1.1: ThemeData dark + light (Ethereal Lumens + Luminous Clarity)
**Arquivos:**
- `lib/app/theme/app_theme.dart` — ThemeData dark + light (M3)
- `lib/app/theme/app_accents.dart` — 10 cores de acento (accents.ts)

**Fonte:** `pianolouvorja/app/src/design-system/themes/`

**Verificação:**
- [ ] useMaterial3: true
- [ ] ColorScheme dark com surface=#131313, onSurface=#e5e2e1
- [ ] ColorScheme light com surface=#f8f9ff, onSurface=#191c20
- [ ] Plus Jakarta Sans via google_fonts
- [ ] Assimetria aplicada nos widgets theme (cardTheme, buttonTheme)
- [ ] 10 acentos: azure, sky, teal, emerald, apricot, orange, coral, rose, violet, slate

### Task 1.2: Design system widgets
**Arquivos:**
- `lib/presentation/shared/widgets/glass_card.dart` — ClipRRect + BackdropFilter
- `lib/presentation/shared/widgets/gradient_background.dart` — Container com LinearGradient
- `lib/presentation/shared/widgets/hymn_list_tile.dart` — item de lista de hino
- `lib/presentation/shared/widgets/section_header.dart` — cabeçalho de seção
- `lib/presentation/shared/widgets/loading_indicator.dart` — loading customizado
- `lib/presentation/shared/widgets/error_view.dart` — tela de erro padronizada
- `lib/presentation/shared/widgets/empty_state.dart` — estado vazio

**Fonte:** `pianolouvorja/app/src/design-system/components/` (GlassCard.vue, GradientBackground.vue)

**Verificação (TDD):**
- [ ] Testes widget para cada componente
- [ ] Widgets renderizam em light e dark mode
- [ ] flutter analyze sem warnings

### Task 1.3: go_router com 5 tabs
**Arquivo:** `lib/app/router.dart`

**Rotas (baseado em `shared/constants/navigation.ts` do Electron):**
```
/                    → HomePage (tab 0 — Início, ícone: home)
/hymns               → HymnsPage (tab 1 — Hinos, ícone: playlist)
/hymns/:albumId      → AlbumDetailPage
/hymns/:albumId/:id  → HymnDetailPage
/liturgy             → LiturgyPage (tab 2 — Liturgia, ícone: clipboard-text)
/bible               → BiblePage (tab 3 — Bíblia, ícone: book-2) [NOVO]
/bible/:bookId/:ch   → BibleChapterPage
/settings            → SettingsPage (tab 4 — Mais, ícone: settings)
/timer               → TimerPage
/countdown           → CountdownPage
```

**Verificação:**
- [ ] StatefulShellRoute.indexedStack (preserva estado de cada tab)
- [ ] Deep link `/hymns/123` funciona
- [ ] Back button funciona

### Task 1.4: Bottom Navigation (5 tabs)
**Arquivo:** `lib/presentation/shared/widgets/main_navigation.dart`

**Tabs (idênticas ao DockFooter do Electron):**
1. Início — TablerIcons.home
2. Hinos — TablerIcons.playlist
3. Liturgia — TablerIcons.clipboardText
4. Bíblia — TablerIcons.book2 [NOVO]
5. Mais — TablerIcons.settings

**Verificação:**
- [ ] 5 tabs com ícones Tabler e labels
- [ ] Estado preservado ao trocar tabs (AutomaticKeepAlive)
- [ ] Indicador de tab ativa

### Task 1.5: HomePage (placeholder funcional)
**Arquivo:** `lib/presentation/home/home_page.dart`

**Conteúdo (baseado em `modules/home/views/HomeView.vue`):**
- Card de boas-vindas com data atual (formato: "Sábado, 10 de Agosto")
- Atalhos rápidos: Hinos, Liturgia, Bíblia, Timer
- Indicador de conexão (online/offline)
- Versão do app no rodapé

**Verificação:**
- [ ] Data atual exibida corretamente
- [ ] Atalhos navegáveis
- [ ] Indicador de conexão reativo

---

## Fase 2: Catálogo de Hinos + Sync (4 semanas)

### Task 2.1: Entidades de domínio (Hymn, Album, Category)
**Arquivos:**
- `lib/domain/entities/hymn.dart` — freezed (baseado em HymnalRow do API.md)
- `lib/domain/entities/album.dart` — freezed (AlbumRecord)
- `lib/domain/entities/album_category.dart` — freezed (Category)

**Schema (do API.md — TypeScript extraído do Electron):**
- Hymn: id, number, title, duration (3 formatos!), hasInstrumental, urlInstrumental
- Album: id, name, subtitle, coverUrl, trackCount
- Category: id, name, albums[]

**Verificação:**
- [ ] Parser de duração (3 formatos: number, "MM:SS", "HH:MM:SS")
- [ ] fromJson/toJson testados

### Task 2.2: Interface abstrata LouvorjaApiClient
**Arquivo:** `lib/domain/repositories/louvorja_api_client.dart`

**Métodos (baseado nos endpoints reais mapeados em API.md):**
- `fetchHymns()` → GET json_db/pt_hymnal
- `fetchAlbums()` → GET json_db/pt_categories
- `fetchAlbumMusics(albumId)` → GET json_db/album_{id}
- `fetchMusicIndex()` → GET json_db/pt_musics
- `fetchBibleBooks()` → GET json_db/pt_bible_book
- `fetchBibleVersions()` → GET json_db/pt_bible_version
- `fetchChapterVerses(versionId, bookId, chapter)` → GET json_db/bible_{vid}_{bid}_{ch}
- `resolveMediaUrl(relativePath)` → constrói URL completa

**Verificação:**
- [ ] Interface pura (sem implementação)
- [ ] Permite troca de backend sem refactor

### Task 2.3: Implementação Dio + retry com backoff
**Arquivos:**
- `lib/core/network/dio_client.dart` — Dio com interceptors
- `lib/data/datasources/remote/louvorja_api_impl.dart` — implementação

**Retry (idêntico ao Electron):**
- 429: backoff exponencial (1s → 1.5s → 2.25s...), max 5
- 5xx: mesmo backoff
- Network error: retry
- Header: `Api-Token`

**Verificação:**
- [ ] Timeout: 10s connect, 30s receive
- [ ] Retry testado com mocktail (MockClient)
- [ ] Cache-buster: sufixo `?YYYYMMDD` nos JSONs

### Task 2.4: Cache local (SharedPreferences ou Hive)
**Arquivo:** `lib/data/datasources/local/catalog_cache.dart`

**Estratégia:**
- Catálogo de hinos: JSON em disco (simples, sem Drift na v1)
- Comparação por hash para detectar mudanças
- TTL: 24h

**Verificação:**
- [ ] Cache funciona offline
- [ ] Invalidação por hash

### Task 2.5: HymnsRepository (offline-first)
**Arquivos:**
- `lib/domain/repositories/hymn_repository.dart` — interface
- `lib/data/repositories/hymn_repository_impl.dart` — implementação

**Métodos:**
- `getAlbums()` — lista coletâneas (filtra IDs 712 e 629)
- `getHymnsByAlbum(albumId)` — hinos de uma coletânea
- `searchHymns(query)` — busca por número/título
- `getHymn(id)` — hino específico

**Verificação:**
- [ ] Offline-first: local primeiro, remote depois
- [ ] Exclusão de IDs 712 e 629

### Task 2.6: HymnsBloc + HymnsPage (lista de coletâneas)
**Arquivos:**
- `lib/presentation/hymns/bloc/hymns_bloc.dart`
- `lib/presentation/hymns/hymns_page.dart`

**Verificação:**
- [ ] States: initial, loading, success, error
- [ ] Grid de coletâneas com capa (cached_network_image), nome, contagem
- [ ] Pull-to-refresh
- [ ] bloc_test para cada transição de estado

### Task 2.7: AlbumDetailPage (lista de hinos por coletânea)
**Features:**
- Lista de hinos ordenados por número
- Busca local com debounce 300ms
- Tap navega para HymnDetailPage

### Task 2.8: HymnDetailPage (letra + favorito)
**Features:**
- Número, título, duração formatada
- Letra completa (se disponível)
- Botão favoritar
- Link YouTube/Spotify

---

## Fase 3: Bíblia (3 semanas) [NOVO]

### Task 3.1: Entidades de domínio (BibleBook, BibleVersion, BibleChapter)
**Schema (do API.md):**
- BibleBook: id, name, abbreviation, chapters, bookNumber (1-66), testament (AT/NT)
- BibleVersion: id, abbreviation (ARA, NVI...), name
- BibleChapter: verses (Map<int, String>)

### Task 3.2: BibleRepository + BibleBloc
**Métodos:**
- `getBooks()` — 66 livros
- `getVersions()` — versões disponíveis
- `getChapter(versionId, bookId, chapter)` — versículos

### Task 3.3: BiblePage (navegação livro → capítulo → versículos)
**UI (baseado em `modules/bible/` do Electron):**
- Lista de livros agrupados AT/NT (BibleBookGrid)
- Grid de capítulos (BibleChapterGrid)
- Lista de versículos (BibleVerseList)
- Seletor de versão (BibleVersionSelect)
- Busca de versículos

---

## Fase 4: Liturgia (4 semanas)

### Task 4.1: Entidade LiturgyItem + LiturgyStore
**Schema (baseado em `modules/liturgy/stores/useLiturgyStore.ts`):**
- WeekdayLiturgies: mapa dia → lista de LiturgyItem
- WeekdayNotes: mapa dia → texto de notas
- CustomLiturgies: liturgias fora dos dias padrão
- LiturgyItem: id, order, type, title, hymnId?, notes?, durationEstimate?

### Task 4.2: LiturgyRepository (persistência local)
- Salvar/carregar liturgia por dia da semana (SharedPreferences ou JSON em disco)
- Clonar liturgia entre dias
- Criar/editar/excluir itens

### Task 4.3: LiturgyPage (timeline visual)
**UI (baseado em `modules/liturgy/`):**
- DayTabs: tabs de dia da semana (seg-dom)
- Timeline: lista vertical de itens com tipo, título, hino associado
- ItemDialog: editar item, associar hino
- CloneDialog: clonar liturgia de outro dia
- NotesPanel: notas por dia

---

## Fase 5: Timer + Countdown (2 semanas)

### Task 5.1: TimerBloc + TimerPage (cronômetro progressivo)
**Baseado em `modules/timer/`:**
- Start/pause/reset
- Display formato 12h/24h configurável
- Notificação ao atingir tempo limite (opcional)

### Task 5.2: CountdownBloc + CountdownPage
**Baseado em `modules/countdown/`:**
- Input de duração
- Lista de countdowns salvos (CountdownSavedList)
- Notificação local + vibração ao terminar
- Foreground service (Android) para background

---

## Fase 6: Polimento + Release (3 semanas)

### Task 6.1: Busca global (hinos + bíblia)
### Task 6.2: Internacionalização (pt-BR, en, es)
### Task 6.3: Acessibilidade (Semantics labels, TalkBack/VoiceOver)
### Task 6.4: Otimização de performance (lazy loading, caching)
### Task 6.5: Build release APK (split-per-abi, R8)
### Task 6.6: Google Play Store listing

---

## Change Log

| Data | Mudança |
|------|---------|
| 2026-08-01 | Versão inicial |
| 2026-08-10 | Rev 2: 5 tabs (Bíblia adicionada). Escala removida. Endpoints corrigidos (JSON estático, não REST). API.md como fonte de verdade. Schema de entidades alinhado com TypeScript do Electron. |
