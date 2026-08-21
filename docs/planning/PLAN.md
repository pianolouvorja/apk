# PLAN — LouvorJA PIANO Flutter

> **SPEC:** [SPEC.md](./SPEC.md) (rev 3 — 2026-08-14)
> **CONTEXT:** [CONTEXT.md](./CONTEXT.md)
> **API:** [API.md](./API.md)
> **DEPLOY:** Fluxo SemVer + GitHub Releases (DEPLOY.md do Ezequias)
> **Criado:** 2026-08-01
> **Updated:** 2026-08-14 — Alinhado com implementacao real (v0.1.0+1)

---

## Fase 0: Setup do Projeto ✓

### Task 0.1: Criar repositorio e estrutura inicial ✓
### Task 0.2: Configurar estrutura Clean Architecture ✓
### Task 0.3: Configurar CI (GitHub Actions) ✓
- analyze (--fatal-infos) + test + build apk --debug

---

## Fase 1: Fundacao + Design System + Navegacao ✓

### Task 1.0: Design tokens extraidos do Electron ✓
### Task 1.1: ThemeData dark + light ✓
### Task 1.2: Design system widgets ✓ (GlassCard, GradientBackground, etc)
### Task 1.3: go_router com 4 tabs ✓
- Rotas: /, /hymns, /tools, /settings, /tools/timer, /liturgy, /bible
### Task 1.4: Bottom Navigation (4 tabs) ✓
- Inicio, Hinos, Ferramentas, Mais
### Task 1.5: HomePage ✓
- Logo, Distrito/Igreja editavel, relogio, banner de update
### Task 1.6: Splash Screen ✓
- Logo, codename, versao dinamica (AppVersion)

---

## Fase 2: Catalogo de Hinos + Sync ✓

### Task 2.1: Entidades de dominio ✓ (Hymn, Album, AlbumCategory)
### Task 2.2: Interface abstrata LouvorjaApiClient ✓
### Task 2.3: Implementacao Dio + retry com backoff ✓
### Task 2.4: Cache local ✓
### Task 2.5: HymnsRepository (offline-first) ✓
### Task 2.6: HymnsBloc + HymnsPage ✓
### Task 2.7: AlbumDetailPage ✓ (com downloads por faixa e album)
### Task 2.8: Downloads offline ✓ (music_offline_repository)

---

## Fase 3: Biblia ✓

### Task 3.1: Entidades ✓ (BibleBook, BibleVersion, BibleChapter)
### Task 3.2: BibleRepository + BibleBloc ✓
### Task 3.3: BiblePage ✓ (livros -> capitulos -> versiculos, seletor de versao)

---

## Fase 4: Liturgia ✓

### Task 4.1: Entidade LiturgyItem + LiturgyStore ✓
### Task 4.2: LiturgyRepository ✓
### Task 4.3: LiturgyPage ✓ (timeline, day tabs, itens, notas, clonar)

---

## Fase 5: Timer + Countdown ✓

### Task 5.1: TimerBloc + TimerPage ✓
### Task 5.2: CountdownBloc + CountdownPage ✓ (presets salvos)
### Task 5.3: ToolsPage container ✓

---

## Fase 6: Auto-Update ✓

### Task 6.1: UpdateService (GitHub Releases API) ✓
### Task 6.2: UpdateBanner com markdown release notes ✓
### Task 6.3: Auto-check ao abrir app (initState Home) ✓
### Task 6.4: Verificacao manual na Settings ✓
### Task 6.5: Download + OpenFilex (nativo) / url_launcher (web) ✓

---

## Fase 7: Audio Playback ✓

### Task 7.1: HymnAudioPlayer (audioplayers) ✓
### Task 7.2: Implementacoes nativa/web/stub ✓

---

## Fase 8: Settings + Configuracoes ✓

### Task 8.1: SettingsPage completa ✓
- Tema, acentos, animacao, glass, idioma, versao, update, limpar dados

---

## Fase 9: MVP Completion (v0.1.1 -> v1.0.0)

### Task 9.1: Fix build APK release — PRIORIDADE MAXIMA
- Problema: audioplayers_android 5.3.0 + AGP 9.0.1 + JDK toolchain
- Sintoma: "does not provide the required capabilities: [JAVA_COMPILER]"
- Solucao candidata: upgrade audioplayers ou fix toolchain Gradle
- **Verificacao:** `flutter build apk --release` gera APK < 25MB

### Task 9.2: Ativar i18n EN e ES
- Traducoes ja existem em assets/translations/
- Desbloquear ChoiceChip EN na SettingsPage
- **Verificacao:** trocar idioma aplica tradução sem restart

### Task 9.3: Miniplayer (#90) — MVP stretch
- Musica em execucao visivel ao trocar de aba
- Widget persistente abaixo da nav bar
- **Verificacao:** tocar hino, trocar de aba, miniplayer visivel com play/pause

### Task 9.4: Busca Global (RF-08) — MVP stretch
- Busca unificada hinos + biblia
- Resultados agrupados por categoria
- **Verificacao:** buscar "amor" retorna hinos e versiculos

### Task 9.5: A11y WCAG AA
- Semantics labels em todos os elementos interativos
- TalkBack/VoiceOver test
- Contraste minimo 4.5:1
- **Verificacao:** auditoria a11y sem critical issues

### Task 9.6: OWASP security review
- Avaliar PAT hardcoded (tornar repo publico ou proxy)
- TLS pinning (opcional)
- **Verificacao:** sem critical/high findings

### Task 9.7: Performance optimization
- Lazy loading de listas
- Image cache otimizado
- Cold start < 3s
- **Verificacao:** Flutter DevTools performance overlay sem jank

### Task 9.8: Google Play Store listing
- Store listing (PT-BR, EN)
- Politica de Privacidade
- Screenshots
- Assinatura keystore (nao debug)
- **Verificacao:** APK assinado e publicado na Play Console

---

## Fase 10: v2.0 — LouvorJA Palco (TV / Cast)

> Depende do MVP v1.0 estavel.

### Task 10.1: mDNS discovery (#58)
- Descoberta automatica de devices Palco na rede local
- Biblioteca: `bonsoir` ou `nsd_platform_interface`

### Task 10.2: WebSocket server (#59)
- Comunicacao bidirecional Operador <-> Palco
- Protocolo: JSON messages sobre WS

### Task 10.3: Cast Custom Receiver (#61)
- Chromecast receiver custom para projecao
- `cast` package ou API nativa

### Task 10.4: DLNA sender (#60)
- Enviar projecao para TVs Samsung/LG/Philips
- Biblioteca: `dlna` ou implementacao custom

### Task 10.5: QR code pairing (#62, #64)
- QR code na tela de projecao para acesso rapido
- Import de dados via QR code

### Task 10.6: Sync via WebSocket (#63)
- Sincronizar liturgia/favoritos entre dispositivos
- Resolucao de conflitos simple (last-write-wins)

### Task 10.7: Import/export .louvorja (#65)
- Formato portatil de configuracao
- Share sheet / file picker

---

## Change Log

| Data | Mudanca |
|------|---------|
| 2026-08-01 | Versao inicial |
| 2026-08-10 | Rev 2: 5 tabs (Biblia adicionada). Escala removida. |
| 2026-08-14 | Rev 3: Status real (Fases 0-8 todas DONE). Navegacao 4 tabs. Fase 9 (MVP completion) com tasks 9.1-9.8. Fase 10 (v2 Palco) com tasks 10.1-10.7 mapeando issues #58-#65. Auto-update e audio marcados como implementados. |
