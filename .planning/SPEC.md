# SPEC: LouvorJA PIANO Mobile (Flutter)

> **Status:** Atualizado (rev 2 — alinhado com codebase Electron)
> **Author:** Rafael Zendron
> **Created:** 2026-08-01
> **Updated:** 2026-08-10 — Analise modulo-a-modulo do Electron
> **Approved by:** Pendente (Ezequias Fonseca)
> **Repo alvo:** `github.com/pianolouvorja/mobile` (a criar)
> **Metodologia:** Spec-Driven Development + OSS Project Excellence

---

## 1. Contexto

O LouvorJA PIANO é um aplicativo desktop (Electron 43 + Vue 3) usado por igrejas
adventistas para gerenciamento de cultos: liturgia, hinos, letras, bíblia,
cronômetros, media player e projeção multi-tela. A versão desktop é completa
(~37.000 LOC em 12 módulos), porém limitada a Windows/Mac/Linux — não atende o
público mobile (Android/iOS), que representa a maior fatia de usuários potenciais
no Brasil.

Esta SPEC define uma **versão mobile Flutter** baseada na **análise direta do
codebase Electron** (`pianolouvorja/app` branch main). Cada módulo do desktop foi
avaliado para determinar o que faz sentido no celular.

### Arquitetura: Operador + Palco

O app Electron hoje acumula dois papéis: **operador** (controle do culto) e
**projetor** (renderização multi-tela). No ecossistema mobile, esses papéis são
**separados em apps distintos**:

| App | Papel | Plataforma | Descrição |
|-----|-------|-----------|-----------|
| **LouvorJA PIANO** (este app) | Operador | Android, iOS | Controle do culto na mão do operador |
| **LouvorJA Palco** (futuro) | Projetor | Android TV, Apple TV, Chromecast, AirPlay, Tizen, LG webOS, Roku TV, Hisense VIDAA | Renderiza projeção em tela cheia |

O app mobile (Operador) **não projeta** -- ele **comanda**. O operador toca
"Projetar" e o app envia o comando via rede local (mDNS + WebSocket, mesmo
protocolo do SPEC-SYNC) para o app Palco mais proximo.

Isso significa:
- As features de projeção do Electron voltam ao escopo mobile como **comandos
  de projeção** (RF-09), não como renderização local
- O modulo de sync (SPEC-SYNC) ganha uma camada de **controle em tempo real**
- O operador pode ter múltiplos Palcos pareados (ex: tela principal + lobby)

### Arquitetura de Dados: Online-First + Offline Opcional

O app funciona como o piano-web: **sem obrigar download nenhum**.

| Estado | Comportamento |
|--------|--------------|
| **Online (default)** | Hinos, liturgia e bíblia carregam via API em tempo real. Zero download necessário. Streaming de áudio se aplicável. |
| **Offline (opcional)** | Usuário pode baixar hinos específicos ou o catálogo completo. Botão "Baixar" por hino + "Baixar tudo" nas configurações. |
| **Cache automático** | Hinos já acessados ficam em cache local (LRU). Reabrir é instantâneo, mesmo offline. Cache transparente ao usuário. |

Isso significa:
- RF-02 (Offline) deixa de ser "baixar tudo obrigatório" e vira "download opcional"
- RF-07 (Sync) muda de "download de catálogo" para "sincronização incremental + cache LRU"
- O app é útil imediatamente após instalar, sem nenhum passo extra

### Análise Modular (Electron -> Mobile)

| Módulo Electron | LOC | Arquivos | Decisão Mobile | Justificativa |
|----------------|-----|----------|----------------|---------------|
| **home** | 551 | 8 | ENTRA COMPLETO | Painel do dia, atalhos |
| **albums** (hinos) | 3.862 | 15 | ENTRA COMPLETO | Catálogo + busca + letras |
| **liturgy** | 9.662 | 24 | ENTRA ADAPTADO | Maior módulo. Projeção sai |
| **bible** | 3.353 | 17 | ENTRA COMPLETO | Leitura + busca de versículos |
| **timer** | 1.995 | 14 | ENTRA ADAPTADO | Projeção sai |
| **countdown** | 2.500 | 15 | ENTRA ADAPTADO | Projeção sai |
| **settings** | 4.255 | 27 | ENTRA PARCIAL | Appearance sim, projeção não |
| **sync** | 1.097 | 7 | ENTRA REDESENHADO | Download de catálogo via API |
| ~~media~~ | 3.863 | 19 | NÃO ENTRA | Player local + PPTX + slides |
| ~~clock~~ | 2.298 | 14 | NÃO ENTRA | Exclusivo de projeção |
| ~~random~~ | 3.687 | 16 | NÃO ENTRA (v2) | Sorteio depende de projeção |
| ~~projection~~ | ~3.000 | — | NÃO ENTRA | Multi-tela desktop-only |

**Cobertura mobile:** ~22.000 LOC de funcionalidade relevante (60% do desktop).
As features excluídas (~15.000 LOC) sao todas desktop-only: projeção multi-tela,
media player local, conversão PPTX, detection de monitores, Electron IPC.

---

## 2. Requisitos Funcionais

### RF-01: Catálogo de Hinos e Coletâneas
**User Story:**
> Como líder de culto, quero buscar e visualizar hinos do Hinário Adventista
> e coletâneas (Louvor JA, Canta Igreja, Vencedores), para selecionar hinos
> durante o planejamento ou execução do culto.

**Módulo Electron de origem:** `modules/albums/` (AlbumsView, AlbumCollectionView)

**Critérios de Aceite (EARS):**
- WHEN o usuário abre a tab Hinos THE SYSTEM SHALL exibir a lista de
  coletâneas disponíveis com nome, capa e contagem de hinos
- WHEN o usuário toca em uma coletânea THE SYSTEM SHALL exibir a lista de
  hinos ordenados por número
- WHEN o usuário digita na barra de busca THE SYSTEM SHALL filtrar hinos por
  número, título ou trecho de letra (debounce 300ms, resposta < 200ms)
- WHEN o usuário toca em um hino THE SYSTEM SHALL exibir letra completa,
  número, tom original e link para tocar no YouTube/Spotify
- IF o hino foi baixado previamente THE SYSTEM SHALL exibir indicação visual
  "disponível offline"
- THE SYSTEM SHALL excluir coletâneas com IDs 712 e 629 (hardcoded no Electron)

### RF-02: Letras de Hinos (Offline)
**User Story:**
> Como músico, quero acessar letras de hinos sem internet, para tocar durante
> o culto sem depender de conexão.

**Módulo Electron de origem:** `modules/albums/components/AlbumLyricDialog.vue`

**Critérios de Aceite:**
- WHEN o usuário marca um hino como favorito THE SYSTEM SHALL baixar e
  armazenar letra + metadados localmente
- WHILE o dispositivo está offline THE SYSTEM SHALL exibir apenas hinos
  previamente baixados, com indicador visual claro
- WHEN o usuário remove um hino dos favoritos THE SYSTEM SHALL liberar o
  espaço de armazenamento correspondente

### RF-03: Liturgia do Dia
**User Story:**
> Como líder de culto, quero visualizar e editar a ordem da liturgia do
> sábado, para seguir o roteiro do culto corretamente.

**Módulo Electron de origem:** `modules/liturgy/` (LiturgyView, LiturgySidebar,
LiturgyTimeline, LiturgyItemDialog, LiturgyCloneDialog, LiturgyNotesPanel)

**Critérios de Aceite:**
- WHEN o usuário abre a tab Liturgia THE SYSTEM SHALL exibir a liturgia
  do sábado atual em formato timeline com itens ordenados
- WHEN o usuário seleciona um dia da semana THE SYSTEM SHALL exibir a
  liturgia correspondente (tabs de dia como no Electron)
- WHEN o usuário toca em um item da liturgia THE SYSTEM SHALL exibir detalhes:
  hino selecionado, observações, duração estimada
- WHEN o usuário edita um item THE SYSTEM SHALL permitir associar um hino
  do catálogo àquele item de liturgia
- IF a liturgia tiver um hino associado THE SYSTEM SHALL permitir navegar
  direto para a letra daquele hino
- THE SYSTEM SHALL permitir clonar liturgia entre dias (LiturgyCloneDialog)
- THE SYSTEM SHALL persistir notas por dia da semana (LiturgyNotesPanel)
- THE SYSTEM SHALL permitir criar liturgias customizadas fora dos dias padrão

### RF-04: Bíblia (NOVO — não estava na SPEC original)
**User Story:**
> Como pastor/ancião, quero ler e buscar versículos da Bíblia no celular,
> para consulta rápida durante o culto ou estudo.

**Módulo Electron de origem:** `modules/bible/` (BibleView, BibleNavPanel,
BibleBookGrid, BibleChapterGrid, BibleVerseList, BibleVersionSelect)

**Critérios de Aceite:**
- WHEN o usuário abre a tab Bíblia THE SYSTEM SHALL exibir a lista de livros
  agrupados por Antigo e Novo Testamento
- WHEN o usuário seleciona um livro THE SYSTEM SHALL exibir os capítulos
- WHEN o usuário seleciona um capítulo THE SYSTEM SHALL exibir os versículos
- THE SYSTEM SHALL permitir escolher versão (ARA, NVI, ACF, etc.)
- WHEN o usuário digita na busca THE SYSTEM SHALL buscar versículos por texto
- IF o capítulo foi baixado previamente THE SYSTEM SHALL exibir offline
- THE SYSTEM SHALL permitir selecionar versículos (destaque visual)

### RF-05: Cronômetro e Contagem Regressiva
**User Story:**
> Como líder de culto, quero um cronômetro para controlar o tempo de cada
> item da liturgia, para que o culto não se estenda além do planejado.

**Módulos Electron de origem:** `modules/timer/` (TimerView) +
`modules/countdown/` (CountdownView, CountdownSavedList)

**Critérios de Aceite:**
- WHEN o usuário abre Utilitários THE SYSTEM SHALL oferecer Timer (progressivo)
  e Countdown (regressivo) como ferramentas separadas
- WHEN o usuário inicia um countdown THE SYSTEM SHALL exibir o tempo restante
  em destaque, com notificação local ao terminar
- WHEN o countdown atinge zero THE SYSTEM SHALL emitir notificação local
  com som opcional e vibração
- IF o app estiver em background THE SYSTEM SHALL manter a contagem via
  notificação persistente (foreground service no Android)
- THE SYSTEM SHALL permitir salvar countdowns predefinidos (ex: 10min sermão,
  5min anúncios) como o Electron (CountdownSavedList)
- THE SYSTEM SHALL permitir configurar formato de exibição (12h/24h), cor

### RF-06: Configurações e Aparência
**User Story:**
> Como usuário, quero configurar o app (idioma, tema, acento de cor, glass,
> tamanho de fonte) para adaptar à minha preferência visual.

**Módulo Electron de origem:** `modules/settings/views/AppearanceView.vue` +
`modules/settings/components/` (AccentColorCard, InteractionModeCard,
ThemeOrbitalSwitcher)

**Critérios de Aceite:**
- WHEN o usuário abre Configurações THE SYSTEM SHALL oferecer: tema
  (claro/escuro/sistema), tamanho de fonte, idioma (pt-BR, es, en)
- WHEN o usuário altera o tema THE SYSTEM SHALL aplicar imediatamente sem
  reiniciar o app (mesmo comportamento do Electron ThemeOrbitalSwitcher)
- THE SYSTEM SHALL oferecer 10 cores de acento (azure, sky, teal, emerald,
  apricot, orange, coral, rose, violet, slate) — default: orange
- THE SYSTEM SHALL oferecer 3 perfis de animação (dynamic, soft, mist)
- THE SYSTEM SHALL permitir ajustar intensidade de glass/blur (slider 0-100,
  default 60) — mesmo cálculo do Electron: `blurPx = 4 + (intensity/100) * 24`
- IF o sistema estiver em modo escuro THE SYSTEM SHALL usar tema escuro por
  padrão na primeira execução

### RF-07: Sincronização de Catálogo (Online)
**User Story:**
> Como usuário, quero baixar atualizações do catálogo de hinos e bíblia
> quando tiver internet, para ter sempre as coletâneas mais recentes.

**Módulo Electron de origem:** `modules/sync/` (library-catalog, library-download)

**Critérios de Aceite:**
- WHEN o app detecta conexão de internet THE SYSTEM SHALL verificar se há
  atualizações do catálogo disponíveis (comparando hash com última sincronização)
- WHEN há atualizações THE SYSTEM SHALL exibir badge "Atualizações disponíveis"
- WHEN o usuário toca em "Atualizar" THE SYSTEM SHALL baixar o catálogo
  incrementalmente (apenas novos/alterados) sem travar a UI
- IF o download falhar THE SYSTEM SHALL exibir mensagem de erro e permitir
  retry sem perder dados baixados anteriormente
- THE SYSTEM SHALL retry automaticamente em caso de 429 (rate limit) com
  backoff exponencial (1s -> 1.5s -> 2.25s...), max 5 tentativas
- THE SYSTEM SHALL retry em 5xx e network errors com mesmo backoff

### RF-08: Busca Global
**User Story:**
> Como usuário, quero buscar hinos e versículos bíblicos numa única busca,
> para encontrar qualquer informação rapidamente.

**Critérios de Aceite:**
- WHEN o usuário toca no ícone de busca global THE SYSTEM SHALL exibir um
  campo que busca em hinos e bíblia simultaneamente
- WHEN o usuário digita THE SYSTEM SHALL exibir resultados agrupados por
  categoria (Hinos, Bíblia)
- WHEN o usuário toca em um resultado THE SYSTEM SHALL navegar para a tela
  correspondente com o item selecionado

---

## 3. Requisitos Não-Funcionais

| Categoria | Requisito | Métrica |
|-----------|-----------|---------|
| Performance | Tempo de inicialização (cold start) | < 3s em dispositivo mid-range |
| Performance | Busca de hinos (debounce) | < 200ms resposta após debounce |
| Performance | Navegação entre tabs | < 16ms frame render (60fps) |
| Armazenamento | Cache offline de 500 hinos + bíblia | < 80MB total |
| Bateria | Uso em background (cronômetro) | < 2% bateria/hora |
| Segurança | Dados do usuário em repouso | SQLite (sem dados pessoais) |
| Segurança | Transferência de dados | TLS 1.2+ para todas as requisições |
| Acessibilidade | Contraste de texto | WCAG 2.1 AA (4.5:1 mínimo) |
| Acessibilidade | Suporte a TalkBack/VoiceOver | 100% dos elementos rotulados |
| Internacionalização | Idiomas suportados | pt-BR (default), es, en |
| Cobertura | Test coverage | >= 90% (lines) |
| CI | Pipeline de quality | analyze + test + build (Android) |
| Tamanho | APK release (arm64) | < 25MB (sem catálogo offline) |
| Compatibilidade | Android minSdk | 24 (Android 7.0) |
| Compatibilidade | iOS min | 15.0 |

---

## 4. Fora de Escopo (v1 Mobile)

### Features desktop-only (NÃO entram na renderização local)

- **Projeção multi-tela local** — o Operador não renderiza projeção. Comanda o Palco via rede
- **Media Player local** — player de áudio/video/slides com controles (3.863 LOC)
- **Relógio projetável** — clock analógico/digital para tela secundária (2.298 LOC)
- **Sorteio aleatório** — depende de projeção para fazer sentido (3.687 LOC)
- **Conversão de PPTX** — requer LibreOffice/Office no host
- **FTP sync** — complexidade de protocolo nativo
- **Catálogo extractor** — ferramenta desktop do Electron
- **Detecção de monitores** — API desktop-only (DisplaysApi)
- **Electron IPC** — DialogApi, PresentationApi, WorkspaceApi, CatalogApi extract

### Features futuras (v2.0+)

- **App LouvorJA Palco** (Android TV, Apple TV, Chromecast, AirPlay, Tizen, LG webOS, Roku TV, Hisense VIDAA) — v2.0
- **Comando de projeção via rede** (RF-09: Operador -> Palco via mDNS+WS) — v2.0
- **Sorteio aleatório** (random) — v2.0
- **Colaboração em tempo real** (multi-usuário editando liturgia) — v3.0
- **Player de áudio streaming** (instrumental) — v2.0
- **Notificações push** (lembrete de escala) — v2.0
- **Multi-device sync** (liturgia/favoritos entre celular e desktop) — v2.0

---

## 5. Design Tokens

> **NÃO criamos tokens do zero.** O design system completo já existe nos repos
> `pianolouvorja/app` (Vue+Vuetify+Tailwind 4) e `pianolouvorja/web` (PWA).
>
> O arquivo **[DESIGN-TOKENS.md](./DESIGN-TOKENS.md)** contém a tradução completa
> de todos os tokens TypeScript/CSS do design system Vue para equivalentes
> Flutter (Material Design 3 + `ThemeData`).
>
> **Fonte oficial:** https://github.com/pianolouvorja/app/tree/main/src/design-system

### Resumo (tokens críticos)

| Token | Valor | Origem (arquivo Electron) |
|-------|-------|--------------------------|
| `primary` | `#2196F3` | `tokens/colors.ts` |
| `secondary` | `#78D6D2` | `tokens/colors.ts` |
| `brandYellow` | `#F8C800` | `tokens/colors.ts` — logo oficial |
| Dark bg/surface | `#131313` | `tokens/colors.ts` — tema "Ethereal Lumens" |
| Light bg/surface | `#F8F9FF` | `tokens/colors.ts` — tema "Luminous Clarity" |
| `spacingUnit` | 8px grid | `tokens/spacing.ts` |
| `radius.sm` | TL+BR 8px | `tokens/radius.ts` — assimetria de marca |
| `radius.lg` | TL+BR 16px | `tokens/radius.ts` — cards |
| Glass blur default | 16px (slider 0-100) | `tokens/blur.ts` |
| Font | Plus Jakarta Sans | `styles/base.css` |
| Accent default | orange `#E0895A` | `themes/accents.ts` |
| Icons | Tabler Icons v3.44+ | `tabler_icons_plus` (Flutter) |

### Assimetria de marca (CRÍTICO)
TL (top-left) + BR (bottom-right) arredondados; TR + BL retos.
Esta é a **assinatura visual** do projeto — nunca usar `BorderRadius.circular()`.

### Navegação (5 tabs)

| Tab | Ícone Tabler | Rota | Módulo Electron |
|-----|-------------|------|-----------------|
| Início | `home` | `/` | home |
| Hinos | `playlist` | `/hymns` | albums |
| Liturgia | `clipboard-text` | `/liturgy` | liturgy |
| Bíblia | `book-2` | `/bible` | bible (NOVO) |
| Mais | `settings` | `/settings` | settings + timer + countdown |

---

## 6. API (catálogo de hinos e Bíblia)

> **Detalhe completo:** [API.md](./API.md) — endpoints, schemas, retry, cache

- **Atual:** JSON estático em `https://api.louvorja.com.br/json_db` (header `Api-Token`)
- **Futuro:** API REST própria em `https://api.louvorja.com.br/documentation`
- Flutter usa interface abstrata `LouvorjaApiClient` -> troca de backend sem refactor
- Endpoints reais mapeados: `pt_hymnal`, `pt_categories`, `album_{id}`,
  `pt_bible_book`, `pt_bible_version`, `bible_{versionId}_{bookId}_{chapter}`

---

## 7. Dependências

### Técnicas (Flutter packages)

| Package | Versão | Função |
|---------|--------|--------|
| `flutter` | 3.44+ | SDK base |
| `flutter_bloc` | ^9.0.0 | State management |
| `dio` | ^5.7.0 | HTTP client |
| `go_router` | ^16.0.0 | Declarative routing |
| `tabler_icons_plus` | ^3.44.0 | Ícones (paridade com Electron v3.45.0) |
| `google_fonts` | ^6.2.1 | Plus Jakarta Sans |
| `easy_localization` | ^3.0.7 | i18n |
| `cached_network_image` | ^3.4.1 | Cache de imagens |
| `freezed` / `freezed_annotation` | ^3.0.0 | Modelos imutáveis |
| `json_serializable` | ^6.8.0 | JSON serialization |
| `logger` | ^2.5.0 | Logging estruturado |
| `bloc_test` | ^10.0.0 | Testes de BLoC |
| `mocktail` | ^1.0.4 | Mocks para testes |

---

## 8. Arquitetura

Clean Architecture + BLoC (3 camadas):

- **Presentation:** Widgets + Pages + BLoCs
- **Domain:** Entities + Repository interfaces + Use Cases
- **Data:** Repository implementations + DTOs + Data sources (remote via Dio)

### Por que BLoC?
- Ecossistema mais maduro para testes (`bloc_test`)
- Paridade conceitual com Pinia stores do Electron (1 store = 1 bloc)
- Suporte nativo a streaming (reativo)

---

## 9. Riscos

| Risco | Prob | Impacto | Mitigação |
|-------|------|---------|-----------|
| API LouvorJA não expõe endpoints mobile | Média | Alto | Mapeamento já feito em API.md |
| Catálogo de hinos muito grande para mobile | Baixa | Médio | Paginação + download sob demanda |
| Performance em Android low-end | Média | Médio | Lazy loading + caching agressivo |
| Bateria drenando com cronômetro em bg | Média | Médio | Foreground service otimizado |
| Tamanho do APK excede limite | Baixa | Baixo | R8 + split-per-abi |

---

## 10. EULA / Termos de Uso

**Decisão: NÃO incluir EULA no v1.0.**

Justificativa:
- App gratuito e open-source, sem coleta de dados pessoais, sem pagamentos
- LGPD: o app não coleta, armazena ou transmite dados pessoais do usuario
- Hinos e liturgia sao publicos (api.louvorja.com.br), nao ha licenciamento restritivo
- Apps Android raramente exigem EULA -- Google Play ja exige Politica de Privacidade
- EULA num app de igreja gera fricção desnecessaria sem beneficio legal real

**Politica de Privacidade**: sim, obrigatoria no Google Play. Documento simples
explicando que o app nao coleta dados, so acessa api.louvorja.com.br e armazena
liturgia/favoritos localmente no dispositivo.

**Revisao**: se futuramente o app tiver:
- Contas de usuario (login/sync na nuvem)
- Dados pessoais (nome, email, telefone)
- Pagamentos (assinatura premium)
- Audio streaming (licenciamento musical)

...ai sim EULA/ToS passa a fazer sentido.

---

## 11. Roadmap de Releases

| Versão | Foco | RFs | Prazo |
|--------|------|-----|-------|
| v0.1.0-alpha | Estrutura + navegação + design system | RF-06 (parcial) | 3 sem |
| v0.2.0-alpha | Catálogo de hinos + busca | RF-01, RF-07 | 4 sem |
| v0.3.0-alpha | Letras offline + favoritos | RF-02 | 2 sem |
| v0.4.0-alpha | Bíblia completa | RF-04 | 3 sem |
| v0.5.0-beta | Liturgia (criar/editar/timeline) | RF-03 | 4 sem |
| v0.6.0-beta | Timer + Countdown | RF-05 | 2 sem |
| v0.7.0-beta | Busca global + polimento | RF-08 | 2 sem |
| v1.0.0 | Release Google Play | Todas | 3 sem |

---

## 12. Change Log

| Data | Autor | Mudança |
|------|-------|---------|
| 2026-08-01 | Rafael | Versão inicial |
| 2026-08-10 | Rafael | Rev 2: Análise modulo-a-modulo do Electron. Bíblia adicionada (RF-04). Escala de músicos removida (não existe no Electron). Timer/Countdown consolidados em RF-05. Busca global ajustada (hinos+bíblia, sem escala). Navegação mudou de 4 para 5 tabs. Arquitetura Operador+Palco. EULA: nao incluir v1.0. |
