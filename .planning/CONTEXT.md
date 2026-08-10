# CONTEXT.md — LouvorJA PIANO Flutter v0.1.0 (Planning)

> Contexto técnico completo para AI agents trabalharem sem precisar
> explorar o codebase. Última atualização: 2026-08-01. Referências:
> SPEC.md, PLAN.md, AGENTS.md.

---

## Visão Geral do Projeto

O LouvorJA PIANO é um aplicativo de gerenciamento de cultos adventistas.
A versão desktop atual (Electron 43 + Vue 3 + Vuetify) está em produção
(v1.14.8) com 14 módulos: albums, bible, clock, countdown, draw, home,
liturgy, media, random, settings, starting, sync, timer.

**Este projeto (NOVO):** Versão mobile Flutter (Android + iOS), simplificada,
focada nas funcionalidades essenciais para uso no celular.

- **Repo alvo:** `github.com/pianolouvorja/mobile` (a criar)
- **Repo desktop (referência):** `github.com/pianolouvorja/app`
- **Repo web (referência PWA):** `github.com/pianolouvorja/web`
- **Site institucional:** `github.com/pianolouvorja/site` (vazio)
- **Fase atual:** Planning (SPEC + PLAN criados, zero código Flutter)
- **AppId desktop:** `com.louvorja.piano`
- **AppId mobile (previsto):** `com.louvorja.piano.mobile`

---

## Estado do Código-Fonte de Referência (Desktop Electron)

### Métricas do app Electron (referência)

| Métrica | Valor |
|---------|-------|
| Arquivos .vue | 98 |
| Módulos | 14 |
| Stores Pinia | 12 |
| Versão | v1.14.8 |
| Electron | 43.1.0 |
| electron-builder | 26.15.3 |
| Vue | 3.5.38 |
| TypeScript | ~6.0.0 |
| Vite | 8.0.16 |
| Vuetify | 4.1.4 |
| Tailwind CSS | 4.3.2 |
| Biome (linter) | (config presente) |

### Módulos do App Desktop (mapa para Flutter)

| Módulo Desktop | Linhas (est.) | Estado | Vai pro Flutter? | Fase |
|----------------|---------------|--------|-------------------|------|
| `albums` | ~1500 | Completo | **SIM** (Hinos) | F2 |
| `bible` | ~1200 | Completo | Não (v2) | — |
| `clock` | ~800 | Completo | **SIM** (parcial) | F4 |
| `countdown` | ~1000 | Completo | **SIM** | F4 |
| `draw` | ~? | Incompleto | Não | — |
| `home` | ~400 | Completo | **SIM** (Início) | F1 |
| `liturgy` | ~2000 | Completo | **SIM** | F3 |
| `media` | ~2000 | Completo | Não (desktop-only) | — |
| `random` | ~800 | Completo | Não (v2) | — |
| `settings` | ~1500 | Completo | **SIM** (parcial) | F1 |
| `starting` | ~300 | Completo | **SIM** (splash) | F1 |
| `sync` | ~1000 | Completo | **SIM** (catálogo sync) | F2 |
| `timer` | ~1000 | Completo | **SIM** | F4 |

### Arquivos-Chave do Desktop (referência para port)

| Arquivo | Função |
|---------|--------|
| `src/modules/albums/views/AlbumsView.vue` | Tela principal de hinos/coletâneas |
| `src/modules/albums/views/AlbumCollectionView.vue` | Lista de hinos de uma coletânea |
| `src/modules/albums/stores/useAlbumsStore.ts` | Store de álbuns (Pinia) |
| `src/modules/albums/composables/useAlbums.ts` | Composable com lógica de álbuns |
| `src/modules/liturgy/views/LiturgyView.vue` | Tela de liturgia |
| `src/modules/liturgy/stores/useLiturgyStore.ts` | Store de liturgia |
| `src/modules/sync/stores/useLocalLibraryStore.ts` | Store de biblioteca local |
| `electron/catalog-extractor.mjs` | Extrai catálogo de hinos |
| `electron/ftp.mjs` | FTP sync (não vai pro mobile) |
| `electron/crypto.mjs` | Ofuscação AES-256-CBC local |
| `electron/workspace.mjs` | Gerência de arquivos locais |
| `electron/constants.mjs` | Constantes (API_BASE_URL etc) |
| `src/router/index.ts` | Router Vue (14 módulos) |
| `src/locales/pt-BR.ts` | Strings i18n em português |
| `src/design-system/` | Componentes de design (Glass, Background, etc) |
| `build/icon.png` | Ícone do app |

### Electron IPC Handlers (NÃO aplicáveis ao mobile)

Os seguintes módulos Electron são desktop-only e **não serão portados**:
- `electron/ipc/web-projection.mjs` — projeção multi-tela
- `electron/ipc/presentation-convert.mjs` — conversão PPTX
- `electron/ipc/displays.mjs` — detecção de monitores
- `electron/player/*.html` — players de mídia desktop
- `electron/ftp.mjs` — cliente FTP

---

## API do LouvorJA (referência)

### Endpoints conhecidos (do código Electron)

| Endpoint | Método | Função |
|----------|--------|--------|
| `{API_BASE_URL}/params?type=env` | GET | Busca credenciais FTP/env |
| `{API_BASE_URL}/catalog` | GET (?) | Catálogo de hinos (a confirmar) |
| `{API_BASE_URL}/tracks` | GET (?) | Lista de faixas (a confirmar) |

> **IMPORTANTE:** Os endpoints exatos precisam ser confirmados com Ezequias.
> O desktop hoje usa API para auth + FTP para download de mídia. O mobile
> precisa de endpoints REST para catálogo de hinos, letras, liturgia e escala.

### Constantes (de `electron/constants.mjs`)

| Constante | Valor |
|-----------|-------|
| `APP_PRODUCT_NAME` | "LouvorJA - PIANO" |
| `APP_USER_DATA_DIR` | (definido em constants.mjs) |
| `API_BASE_URL` | (definido em constants.mjs, a confirmar URL exata) |
| `APP_DESKTOP_ID` | "louvorja-piano" |

---

## Design System (referência — NÃO criar do zero)

> O design system já está estabelecido em `pianolouvorja/app` e `pianolouvorja/web`.
>
> **Arquivo completo de tradução web→Flutter:** [DESIGN-TOKENS.md](./DESIGN-TOKENS.md)
>
> **Source:** `src/design-system/` em ambos os repos.

### Estrutura do Design System (existente)

```
src/design-system/
├── tokens/          # colors, spacing, radius, zIndex, blur, breakpoints
├── themes/          # etherealLumens, luminousClarity, accents, interactions
├── animations/      # dock, page transitions
├── composables/     # useThemeManager, useBlurSystem, usePageTransition
├── components/      # GlassCard, BlurContainer, GradientBackground, Dock, etc
└── types/           # DockNavItem, etc
```

### Paleta Real (extraída do código)

| Token | Light | Dark |
|-------|-------|------|
| Background | `#F8F9FF` | `#131313` |
| Surface | `#F8F9FF` | `#131313` |
| Surface Elevated | `#FFFFFF` | `#1E1E1E` |
| Surface Card | `#FFFFFF` | `#242424` |
| On Surface | `#191C20` | `#E5E2E1` |
| Primary | `#2196F3` | `#2196F3` (default, overrideável por accent) |
| Brand Yellow | `#F8C800` | `#F8C800` |

### Componentes → Flutter (ver DESIGN-TOKENS.md §11)

| Componente Vue | Flutter Widget |
|----------------|----------------|
| `GlassCard.vue` | `ClipRRect` + `BackdropFilter` + `Container` |
| `BlurContainer.vue` | `BackdropFilter` wrapper |
| `GradientBackground.vue` | `Container` com `LinearGradient` |
| `BottomNavigation.vue` | `NavigationBar` (Material 3) |
| `DockFooter.vue` | `NavigationBar` (M3) — dock é desktop-only |
| `MediaCollectionList.vue` | `ListView` + `ListTile` custom |

### Tipografia

Fonte: **Plus Jakarta Sans** (via `@fontsource-variable/plus-jakarta-sans`)
→ Flutter: `google_fonts` package ou bundle `.ttf` em `assets/fonts/`

---

## Estrutura de Dados (referência)

### Entidades do domínio (inferidas do código)

```typescript
// Hymn / Track
{
  id: string
  number: number
  title: string
  albumId: string       // coletânea
  lyric?: string
  key?: string          // tom musical
  youtubeId?: string
  spotifyId?: string
  duration?: number     // segundos
  instrumental?: boolean
}

// Album / Collection
{
  id: string
  name: string
  category: AlbumCategory  // 'hymnal' | 'collection' | 'kids'
  trackCount: number
  coverUrl?: string
}

// LiturgyItem
{
  id: string
  order: number
  type: string          // 'hymn' | 'prayer' | 'reading' | 'announcement'
  title: string
  hymnId?: string
  notes?: string
  durationEstimate?: number
}

// ScheduleItem / Musician (a definir)
{
  id: string
  musicianName: string
  instrument: string
  date: string
}
```

---

## Processo de Teste (planejado)

### Flutter (futuro)

```bash
# Análise estática
flutter analyze

# Testes unitários
flutter test --coverage

# Integration tests
flutter test integration_test/

# Build
flutter build apk --release --split-per-abi
flutter build ipa --release
```

### Cobertura
- **Target:** >= 90% lines
- **Ferramenta:** `flutter test --coverage` + `genhtml`
- **CI:** GitHub Actions com `subosito/flutter-action@v2`

---

## Infraestrutura

### Repositórios GitHub (org `pianolouvorja`)

| Repo | Função | Estado |
|------|--------|--------|
| `pianolouvorja/app` | Desktop Electron | Produção v1.14.8 |
| `pianolouvorja/web` | PWA Vue 3 | Produção v1.15.5 |
| `pianolouvorja/site` | Site institucional | Vazio |
| `pianolouvorja/mobile` | **Flutter (este projeto)** | A criar |

### CI/CD (planejado)

- **GitHub Actions:** `subosito/flutter-action@v2`
- **Gates:** flutter analyze → flutter test → flutter build
- **Distribuição:** Google Play (fastlane), App Store (fastlane)
- **Crash reporting:** Firebase Crashlytics ou Sentry

### Ambiente de Desenvolvimento

| Item | Valor |
|------|-------|
| OS | Linux Mint (Oracle ARM64) ou macOS (build iOS) |
| Flutter SDK | 3.22+ (previsto) |
| Dart SDK | 3.4+ (previsto) |
| Android Studio | Para emulador + SDK |
| Xcode | Para build iOS (requer macOS) |
| Device real | Android 7+ para testes |

---

## Dependências

### Runtime (Flutter packages previstos)

| Package | Versão | Função |
|---------|--------|--------|
| `flutter_bloc` | ^8.1.0 | State management |
| `dio` | ^5.4.0 | HTTP client |
| `drift` | ^2.16.0 | SQLite ORM |
| `sqlite3_flutter_libs` | ^0.5.0 | SQLite native |
| `go_router` | ^14.0.0 | Declarative routing |
| `flutter_secure_storage` | ^9.0.0 | Secure key-value |
| `flutter_local_notifications` | ^17.0.0 | Notificações locais |
| `cached_network_image` | ^3.3.0 | Cache de imagens |
| `flutter_svg` | ^2.0.0 | SVG rendering |
| `google_fonts` | ^6.2.0 | Plus Jakarta Sans |
| `easy_localization` | ^3.0.0 | i18n |
| `permission_handler` | ^11.0.0 | Permissões |
| `connectivity_plus` | ^6.0.0 | Online/offline |
| `freezed` | ^2.5.0 | Modelos imutáveis |
| `json_serializable` | ^6.8.0 | JSON serialization |

### Dev

| Package | Versão | Função |
|---------|--------|--------|
| `build_runner` | ^2.4.0 | Code gen runner |
| `mocktail` | ^1.0.0 | Mocking |
| `bloc_test` | ^9.1.0 | BLoC testing |
| `flutter_lints` | ^4.0.0 | Lint rules |

---

## Decisões de Design Importantes

1. **Flutter e não React Native:** Flutter tem rendering próprio (Skia/Impeller),
   performance superior em animações, e single codebase verdadeira. RN exigiria
   bridges nativos para cada plataforma.

2. **BLoC e não Riverpod:** Paridade conceitual com Pinia stores do desktop.
   Cada store vira um BLoC. BLoC tem melhor tooling de teste (bloc_test).

3. **Versão SIMPLIFICADA:** O mobile NÃO é um port 1:1 do desktop. É um app
   novo, focado no usuário mobile (líder de culto/músico), com subconjunto
   de features. Projeção, FTP, PPTX, media player = desktop-only.

4. **Offline-first:** O app deve funcionar 100% offline após o primeiro download
   do catálogo. Sync é incremental e não-bloqueante.

5. **Paridade visual:** Usar a mesma paleta de cores, tipografia (Plus Jakarta
   Sans) e estilo visual (glass morphism, gradient backgrounds) do desktop.

6. **API como fonte única de verdade:** O catálogo de hinos, liturgia e escala
   vêm da API do LouvorJA. O app faz cache local mas a API é master.

7. **Drift (SQLite) para persistência:** Não usar Hive ou SharedPreferences para
   dados estruturados. Drift é type-safe, tem migrations e suporta queries
   complexas necessárias para busca de hinos.

8. **go_router para navegação:** Suporte nativo a deep links (essencial para
   compartilhar hinos via WhatsApp) e Web URL strategy.

9. **AppId separado:** `com.louvorja.piano.mobile` — não conflitar com o
   desktop `com.louvorja.piano`. Permite instalação side-by-side se futuro
   determinar.

10. **LGPD compliant por design:** O app não coleta dados pessoais. Cache
    local é apenas de hinos/liturgia (dados públicos). Sem tracking, sem ads.

---

## Glossário

| Termo | Significado |
|-------|-------------|
| **PIANO** | Nome interno do app desktop (interface de projeção) |
| **Coletânea** | Conjunto de hinos (ex: Louvor JA 2026, Hinário Adventista) |
| **Hinário** | Hinário Adventista do Sétimo Dia (7º edição) |
| **Louvor JA** | Coletânea de hinos da Juventude Adventista |
| **Liturgia** | Ordem do culto sabatino (hinos, orações, leituras, sermão) |
| **Escala** | Lista de músicos escalados para o culto |
| **Projeção** | Exibição de hinos/letras em tela secundária (desktop-only) |
| **Catálogo** | Base de dados de todas as coletâneas e hinos |
| **FTP Sync** | Download de mídia via FTP (desktop-only, não vai pro mobile) |
| **IASD** | Igreja Adventista do Sétimo Dia |
| **BLoC** | Business Logic Component (padrão de state management Flutter) |
| **Drift** | ORM SQLite type-safe para Dart/Flutter |
