# SPEC: LouvorJA PIANO Mobile (Flutter)

> **Status:** Rev 3 — alinhado com codebase real (v0.1.0+1)
> **Author:** Rafael Zendron
> **Created:** 2026-08-01
> **Updated:** 2026-08-14 — Reflect implementation status + v2 Palco roadmap
> **Approved by:** Pendente (Ezequias Fonseca)
> **Repo:** `github.com/pianolouvorja/apk` (privado)
> **Metodologia:** Spec-Driven Development + SemVer (DEPLOY.md)

---

## 1. Contexto

O LouvorJA PIANO e um aplicativo desktop (Electron 43 + Vue 3) usado por igrejas
adventistas para gerenciamento de cultos: liturgia, hinos, letras, biblia,
cronometros, media player e projecao multi-tela. A versao desktop e completa
(~37.000 LOC em 12 modulos), porem limitada a Windows/Mac/Linux.

A versao mobile Flutter e o app do **Operador** — controle do culto na mao.
Projecao fica para o futuro app **LouvorJA Palco** (v2).

### Arquitetura: Operador + Palco

| App | Papel | Plataforma | Status |
|-----|-------|-----------|--------|
| **LouvorJA PIANO** (este app) | Operador | Android, iOS, Web | v0.1.0+1 (MVP em curso) |
| **LouvorJA Palco** (futuro) | Projetor | Android TV, Chromecast, AirPlay, Tizen, LG webOS, Roku, VIDAA | v2.0 (planejado) |

O app mobile **nao projeta** — ele **comanda**. O operador toca "Projetar" e o
app envia o comando via rede local (mDNS + WebSocket) para o app Palco.

### Arquitetura de Dados: Online-First + Offline Opcional

| Estado | Comportamento |
|--------|--------------|
| **Online (default)** | Hinos, liturgia e biblia carregam via API em tempo real |
| **Offline (opcional)** | Usuario pode baixar hinos especificos ou album completo |
| **Cache automatico** | Hinos ja acessados ficam em cache local (LRU) |

---

## 2. Analise Modular (Electron -> Mobile) — Status Real

| Modulo Electron | LOC | Decisao Mobile | Status | Observacao |
|----------------|-----|----------------|--------|------------|
| **home** | 551 | ENTRA COMPLETO | DONE | Logo, distrito/igreja, relogio, banner update |
| **albums** (hinos) | 3.862 | ENTRA COMPLETO | DONE | Catalogo + busca + capas + downloads |
| **liturgy** | 9.662 | ENTRA ADAPTADO | DONE | Timeline, day tabs, itens, notas (sem projecao) |
| **bible** | 3.353 | ENTRA COMPLETO | DONE | Livros, capitulos, versiculos, versoes |
| **timer** | 1.995 | ENTRA ADAPTADO | DONE | Timer + countdown + presets (sem projecao) |
| **countdown** | 2.500 | ENTRA ADAPTADO | DONE | Consolidado em timer/tools |
| **settings** | 4.255 | ENTRA PARCIAL | DONE | Tema, acentos, glass, idioma, update, limpar dados |
| **sync** | 1.097 | ENTRA REDESENHADO | DONE | Cache local + download opcional |
| **splash** | — | NOVO MOBILE | DONE | Logo + codename + versao |
| **auto-update** | — | NOVO MOBILE | DONE | GitHub Releases + banner + markdown notes |
| **audio player** | 3.863 | ENTRA PARCIAL | DONE | Playback basico (audioplayers), sem PPTX/slides |
| ~~media~~ | — | NAO ENTRA | — | Player local + PPTX + slides (desktop-only) |
| ~~clock~~ | — | NAO ENTRA | — | Exclusivo de projecao |
| ~~random~~ | — | NAO ENTRA (v2) | — | Sorteio depende de projecao |
| ~~projection~~ | — | NAO ENTRA | — | Multi-tela desktop-only |
| ~~miniplayer~~ | — | TODO (MVP stretch) | TODO | #90 — musica visivel ao trocar aba |
| ~~global search~~ | — | TODO (MVP stretch) | TODO | Hinos + biblia unificada |

---

## 3. Requisitos Funcionais

### RF-01: Catalogo de Hinos e Coletaneas — IMPLEMENTADO
- Lista de coletaneas com capa, nome, contagem
- Lista de hinos por coletanea, busca com debounce 300ms
- Download por faixa e por album inteiro
- Exclusao de IDs 712 e 629

### RF-02: Letras de Hinos (Offline) — IMPLEMENTADO
- Download opcional de hinos para acesso offline
- Indicador visual de disponibilidade offline
- Cache LRU automatico

### RF-03: Liturgia do Dia — IMPLEMENTADO
- Timeline de itens por dia da semana
- Day tabs (seg-dom)
- Associar hinos a itens de liturgia
- Notas por dia
- Clonar liturgia entre dias
- Criar liturgias customizadas

### RF-04: Biblia — IMPLEMENTADO
- 66 livros agrupados AT/NT
- Navegacao livro -> capitulo -> versiculos
- Seletor de versao (ARA, NVI, ACF, etc.)
- Busca de versiculos
- Offline apos primeiro acesso (cache)

### RF-05: Cronometro e Contagem Regressiva — IMPLEMENTADO
- Timer progressivo (start/pause/reset)
- Countdown regressivo com presets salvos
- Notificacao local + vibracao ao terminar
- Adicionar/remover presets

### RF-06: Configuracoes e Aparencia — IMPLEMENTADO
- Tema claro/escuro
- 10 cores de acento (azure, sky, teal, emerald, apricot, orange, coral, rose, violet, slate)
- 3 perfis de animacao (dynamic, soft, mist)
- Intensidade de glass (slider 0-100, default 60)
- Idioma (PT-BR ativo; EN e ES preparados mas desativados)
- Versao do app
- Verificar atualizacoes (manual)
- Limpar dados locais

### RF-07: Sincronizacao de Catalogo — IMPLEMENTADO
- Cache local com TTL 24h
- Retry com backoff exponencial em 429/5xx
- Download incremental (hash comparison)

### RF-08: Busca Global — TODO (MVP stretch)
- Busca unificada hinos + biblia
- Resultados agrupados por categoria

### RF-09: Auto-Update via GitHub Releases — IMPLEMENTADO
- Verificacao automatica ao abrir o app (initState da Home)
- Banner no topo com versao, tamanho e release notes
- Release notes em markdown renderizado (flutter_markdown)
- Download + instalacao do APK (nativo) ou link (web)
- Comparacao Semver (tag_name vs version do PackageInfo)
- Token GitHub PAT para repo privado

### RF-10: Playback de Audio — IMPLEMENTADO (parcial)
- Player basico via audioplayers
- Implementacoes nativa/web/stub
- Sem miniplayer visivel entre tabs (TODO #90)

---

## 4. Navegacao (4 tabs)

| Tab | Icone Tabler | Rota | Modulo |
|-----|-------------|------|--------|
| Inicio | `home` | `/` | Home + relogio + banner update |
| Hinos | `playlist` | `/hymns` | Catalogo de coletaneas e hinos |
| Ferramentas | `tools` | `/tools` | Timer, Countdown, Liturgia, Biblia |
| Mais | `settings` | `/settings` | Configuracoes, versao, update |

Biblia e Liturgia sao acessadas via **Ferramentas** (nao sao tabs separadas).
Dentro de Ferramentas: Timer, Liturgia e Biblia tem seus proprios Blocs e pages.

---

## 5. Roadmap de Releases

### MVP — v0.1.x ate v1.0.0

| Versao | Foco | Status |
|--------|------|--------|
| v0.1.0+1 | Fundacao + design system + 5 modulos + auto-update + 439 testes | DONE (release criada) |
| v0.1.1+2 | Fix build APK (audioplayers/JDK), i18n EN/ES ativo | TODO |
| v0.2.0+3 | Miniplayer (#90), busca global (RF-08) | TODO |
| v0.3.0+4 | A11y WCAG AA, performance, polimento | TODO |
| v1.0.0+5 | Release Google Play Store | TODO |

### v2.0 — LouvorJA Palco (TV / Cast)

| Feature | Issue | Descricao |
|---------|-------|-----------|
| mDNS discovery | #58 | Descoberta automatica de devices Palco na rede |
| WebSocket server | #59 | Comunicacao bidirecional Operador <-> Palco |
| DLNA sender | #60 | Enviar projecao para TVs Samsung/LG/Philips |
| Cast Custom Receiver | #61 | Chromecast receiver custom |
| QR code na projecao | #62 | Acesso rapido ao mirror |
| Sync via WebSocket | #63 | Sincronizar dados entre dispositivos |
| Import via QR Code | #64 | Importar dados via webcam (desktop) |
| Import/export .louvorja | #65 | Arquivo portatil de configuracao |

**Dependencia:** o app Palco (v2) precisa do Operador (v1) estavel.

---

## 6. Fora de Escopo (v1 Mobile)

- Projecao multi-tela local
- Media Player local (PPTX, slides, conversao)
- Relogio projetavel
- Sorteio aleatorio
- Deteccao de monitores, Electron IPC, FTP sync
- Multi-device sync (v2)
- Notificacoes push (v2)

---

## 7. Seguranca

- **GitHub PAT hardcoded:** o UpdateService usa um token PAT para acessar
  releases do repo privado. TODO de seguranca:
  - Opcao A: tornar o repo publico (app e MIT, nao tem dados sensíveis)
  - Opcao B: endpoint proxy (api.pianolouvorja.com.br) que consulta GitHub
  - Avaliar com OWASP antes do release na Play Store

---

## 8. Design Tokens

Fonte oficial: `pianolouvorja/app/src/design-system/`
Traducao Flutter: `DESIGN-TOKENS.md`

| Token | Valor | Origem |
|-------|-------|--------|
| Dark surface | `#131313` | Ethereal Lumens |
| Light surface | `#F8F9FF` | Luminous Clarity |
| Accent default | orange `#E0895A` | accents.ts |
| Spacing | 8px grid | spacing.ts |
| Radius | TL+BR (assimetria) | radius.ts |
| Font | Plus Jakarta Sans | google_fonts |
| Icons | Tabler Icons v3.44+ | tabler_icons_plus |

---

## 9. Dependencias

| Package | Versao | Funcao |
|---------|--------|--------|
| flutter | 3.44+ | SDK |
| flutter_bloc | ^9.0.0 | State management |
| dio | ^5.7.0 | HTTP client |
| go_router | ^16.0.0 | Routing |
| tabler_icons_plus | ^3.44.0 | Icones |
| google_fonts | ^6.2.1 | Plus Jakarta Sans |
| easy_localization | ^3.0.7 | i18n |
| cached_network_image | ^3.4.1 | Cache de imagens |
| freezed | ^3.0.0 | Modelos imutaveis |
| audioplayers | ^6.8.1 | Playback de audio |
| flutter_markdown | ^0.7.6 | Release notes renderizados |
| url_launcher | ^6.3.1 | Abrir links externos |
| open_filex | ^4.5.0 | Abrir APK baixado |
| package_info_plus | ^8.0.0 | Versao do app em runtime |

---

## 10. Arquitetura

Clean Architecture + BLoC (3 camadas):
- **Presentation:** Widgets + Pages + BLoCs
- **Domain:** Entities + Repository interfaces
- **Data:** Repository implementations + DTOs + Data sources

---

## 11. Change Log

| Data | Autor | Mudanca |
|------|-------|---------|
| 2026-08-01 | Rafael | Versao inicial |
| 2026-08-10 | Rafael | Rev 2: Analise modular do Electron, Biblia, 5 tabs, arquitetura Operador+Palco |
| 2026-08-14 | Rafael | Rev 3: Status real de implementacao (tudo DONE/TODO). Navegacao 4 tabs (nao 5). RF-09 (auto-update) e RF-10 (audio). Roadmap MVP + v2 Palco com issues #58-#65. Seguranca (PAT). |
