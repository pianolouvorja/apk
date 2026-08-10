# 📱 LouvorJA PIANO Mobile (Flutter) — Relatório Executivo

> **Para:** Ezequias Fonseca (mantenedor)
> **De:** Rafael Zendron
> **Data:** 01/Agosto/2026
> **Assunto:** Planejamento completo do app mobile Flutter do LouvorJA PIANO

---

## 1. O QUE É

Versão **mobile (Android + iOS)** do LouvorJA PIANO, em Flutter. O app desktop
(Electron + Vue 3) está maduro (v1.14.8) mas atende só desktop. O mobile leva o
mesmo conteúdo pro celular do líder de culto/músico.

**NÃO é um port 1:1 do desktop.** É uma versão focada — projeção multi-tela,
FTP, PPTX e media player ficam de fora (são desktop-only).

---

## 2. O QUE O APP FAZ (8 features)

| # | Feature | Descrição |
|---|---------|-----------|
| 1 | **Catálogo de Hinos** | Buscar e visualizar hinos do Hinário Adventista + coletâneas (Louvor JA, Vinda Vitoriosa, etc.) |
| 2 | **Letras Offline** | Baixar letras pra usar sem internet durante o culto |
| 3 | **Liturgia do Dia** | Ordem do culto sabatino (hinos, orações, leituras) |
| 4 | **Cronômetro** | Contagem progressiva e regressiva com notificação ao terminar |
| 5 | **Escala de Músicos** | Quem está escalado pro culto |
| 6 | **Busca Global** | Buscar hinos + liturgia + escala em um só lugar |
| 7 | **Configurações** | Tema claro/escuro, 10 cores de destento, idioma, tamanho de fonte |
| 8 | **Sync de Catálogo** | Baixar atualizações quando tiver internet (incremental, sem travar a UI) |

---

## 3. TECNOLOGIA

| Camada | Escolha | Por quê? |
|--------|---------|----------|
| Framework | **Flutter 3.22+** | Single codebase Android+iOS, rendering próprio (Skia/Impeller) |
| Estado | **BLoC** | Melhor tooling de teste, paridade conceitual com Pinia do desktop |
| Banco local | **Drift (SQLite)** | Type-safe, migrations, queries complexas pra busca de hinos |
| HTTP | **Dio** | Interceptors de retry, timeout, auth |
| Routing | **go_router** | Deep links (compartilhar hino via WhatsApp) |
| Offline | **Drift + connectivity_plus** | 100% funcional sem internet após primeiro download |
| Ícones | **Tabler Icons** (v3.45.0) | Mesma lib já usada no Electron e web |

---

## 4. DESIGN SYSTEM (paridade total com desktop)

Não criamos nada do zero. Tokens extraídos diretamente do código:

- **2 temas:** "Ethereal Lumens" (dark, padrão) + "Luminous Clarity" (light)
- **10 cores de destento** selecionáveis (default: orange)
- **Fonte:** Plus Jakarta Sans
- **Glass morphism:** blur ajustável (slider 0-100)
- **Assinatura visual:** cantos TL+BR arredondados, TR+BL retos (igual desktop)
- **3 perfis de animação:** dynamic, soft (padrão), mist

---

## 5. API (como o app consome dados)

### Hoje (atual)

JSON estático em `https://api.louvorja.com.br/json_db`:

- Catálogos: `pt_hymnal`, `pt_hymnal_1996`, `pt_categories`
- Álbuns: `album_{id}` (hinos de cada coletânea)
- Bíblia: `pt_bible_book`, `pt_bible_version`, `bible_{vid}_{bid}_{cap}`
- Mídia: `/file?path=...` (capas, áudios)
- **Auth:** header `Api-Token` (não Bearer)
- **Retry:** backoff exponencial em 429/5xx (máx 5 tentativas)

### Futuro

API REST própria em `https://api.louvorja.com.br/documentation`

**Estratégia:** interface abstrata `LouvorjaApiClient` → trocar de JSON estático
pra REST sem refactor.

---

## 5.5. ÁUDIO INGLÊS — Pesquisa completa

O SDA Hymnal (inglês) tem 695 hinos. A API Louvor JA não cobre EN, então pesquisei
fontes alternativas. **Tudo testado e confirmado:**

### Cobertura

| Recurso | Cobertura | Fonte | Licença |
|---------|-----------|-------|---------|
| Letras | 695/695 (100%) | NPM `sda-hymnal` | MIT |
| Áudio Cantado | 483/695 (70%) | SacCentral Choir | Ver item abaixo |
| Áudio Instrumental | 695/695 (100%) | MIDI GitHub | GPL |

### 1. Letras — 695 hinos completos (MIT)

NPM `sda-hymnal` — SQLite com título, até 7 estrofes, refrão, autor, referência
bíblica. Repo: `github.com/joshpetit/sda-hymnal`. Uso comercial permitido.

### 2. Áudio Cantado — SacCentral Choir (483 de 695)

Coral adventista que gravou os hinos cantados. MP3s em
`bjaarmy.com/sabbath-school/SSChoir-SDA_Hymns/`.

- **Testado e confirmado:** download real, MP3 válido (64kbps, stereo, ~1MB/hino)
- Playlist oficial M3U com 483 hinos indexados
- Faltam 212 hinos sem gravação desse coral

### 3. Áudio Instrumental — MIDI (695/695, 100% garantido)

Repo `github.com/frazras/SDA-Hymnal-Old-and-New` (GPL). 695 arquivos `.mid`
(~20KB cada, ~15MB total). **Testado e confirmado:** HTTP 200, `audio/midi`.

### 4. Estratégia para os 212 hinos faltantes (cantado)

YouTube grabber via `yt-dlp` — existem playlists com SDA Hymnal cantado.
Fallback final: MIDI sintetizado (garante que todo hino tenha pelo menos melodia).

```
Hino EN → Tem no SacCentral (483)?
            SIM → MP3 coral ✅
            NÃO → YouTube grabber (212)
                    SIM → MP3 ✅
                    NÃO → MIDI fallback ✅
```

### Bônus: 8 hinários históricos EN (5.077 hinos)

O repo `GospelSounders/all-sda-hymnals` tem JSON estruturado de 8 hinários
adventistas históricos (1843-1985). 5.077 hinos com letras — sem áudio, mas
valioso como expansão futura.

### Documentação técnica completa

O arquivo **`AUDIO-SOURCES.md`** (21KB) foi criado com URL patterns, specs
técnicas, exemplos de implementação (Electron/Web/Flutter), schema de cache
SQLite, análise legal, e `saccentral_index.json` com os 483 filenames exatos.

> **Cópia em todos os repos:** `piano-app/docs/`, `piano-web/docs/`,
> `piano-site/docs/`, `pianolouvorja-flutter/.planning/`

### Decisão que preciso de você (NOVA)

| # | Decisão | Impacto |
|---|---------|---------|
| 9 | **SacCentral Choir:** entrar em contato pedindo permissão formal de uso dos 483 MP3s? Ou usamos sem pedir? | Distribuição EN |

---

## 6. ROADMAP (~22 semanas / 5-6 meses)

| Versão | Foco | Semanas |
|--------|------|---------|
| v0.1.0-alpha | Setup + design system + navegação | 4 |
| v0.2.0-alpha | Catálogo de hinos + busca + sync | 4 |
| v0.3.0-alpha | Letras offline + favoritos | 2 |
| v0.4.0-beta | Liturgia do dia | 3 |
| v0.5.0-beta | Cronômetro + countdown | 2 |
| v0.6.0-beta | Escala de músicos | 2 |
| v0.7.0-beta | Busca global + polimento | 2 |
| **v1.0.0** | **Release Google Play + App Store** | 3 |

---

## 7. O QUE JÁ ESTÁ PRONTO

**7 documentos de planejamento completos** em `/pianolouvorja-flutter/.planning/`:

| Documento | O que tem | Tamanho |
|-----------|-----------|---------|
| **SPEC.md** | 8 requisitos funcionais + 14 não-funcionais + riscos + roadmap | 395 linhas |
| **PLAN.md** | 30+ tasks detalhadas em 7 fases, cada uma com arquivo + verificação | 514 linhas |
| **AGENTS.md** | 12 regras de ouro, convenções de código, workflow TDD, CI gates | 384 linhas |
| **CONTEXT.md** | Estado técnico, mapeamento desktop→mobile, 14 módulos analisados | 366 linhas |
| **DESIGN-TOKENS.md** | Todos os tokens TypeScript/CSS traduzidos pra Flutter Material 3 | 339 linhas |
| **API.md** | Endpoints reais, schemas TypeScript→Dart, retry, cache, auth | 277 linhas |
| **AUDIO-SOURCES.md** | Fontes de áudio EN testadas: SacCentral + MIDI + YouTube + letras | ~450 linhas |
| **README.md** | Overview, stack, árvore de arquivos, guia dos documentos | 186 linhas |

**Total:** ~2.900 linhas de planejamento.

**Zero código Flutter ainda.** Próximo passo é a Fase 0 (setup do projeto).

---

## 8. DECISÕES QUE PRECISO DA SUA APROVAÇÃO

| # | Decisão | Impacto | Bloqueia |
|---|---------|---------|----------|
| 1 | **Criar repo `pianolouvorja/mobile`** na org GitHub | Tudo | Imediato |
| 2 | **AppId:** confirmar `com.louvorja.piano.mobile` | Setup | Fase 0 |
| 3 | **Marca:** autorização pra usar "LouvorJA" no app mobile | Release | Fase 7 |
| 4 | **Apple Developer:** conta ($99/ano) pra distribuir iOS | iOS release | Fase 7 |
| 5 | **Liturgia:** dados de liturgia virão da API? Formato? | Fase 3 | Fase 3 |
| 6 | **Escala:** dados de escala virão da API? Formato? | Fase 5 | Fase 5 |
| 7 | **Catálogo:** confirmar formato atual do JSON de hinos | Fase 2 | Fase 2 |
| 8 | **API futura:** quando a REST própria fica pronta? | Arquitetura | Não bloqueia |

> Os itens 1 e 2 bloqueiam o início. Os demais podem ser resolvidos ao longo
> do desenvolvimento (cada um bloqueia só sua fase específica).

---

## 9. CUSTOS ESTIMADOS

| Item | Custo | Quando |
|------|-------|--------|
| Google Play Console | $25 (único) | Release Android |
| Apple Developer Program | $99/ano | Release iOS |
| Flutter SDK + ferramentas | $0 (gratuito) | Imediato |
| Firebase Crashlytics | $0 (free tier) | Release |
| **Total ano 1** | **~$124** | |

---

## 10. RESUMO EXECUTIVO

- App mobile Flutter **simplificado** do LouvorJA PIANO desktop
- **8 features essenciais** (hinos, letras, liturgia, cronômetro, escala, busca, settings, sync)
- **Offline-first:** funciona 100% sem internet após primeiro download
- **Design system idêntico** ao desktop (mesmas cores, fonte, glass morphism, Tabler Icons)
- **API já mapeada** do código real (JSON estático hoje, REST no futuro)
- **Áudio EN resolvido:** 695 letras (MIT) + 483 cantados (SacCentral) + 695 MIDI (GPL) + YouTube p/ 212 faltantes
- **~22 semanas** de desenvolvimento (1 dev + IA)
- **7 documentos de planejamento + doc de áudio completa** prontos pra revisão
- **Zero código ainda** — aguardando sua aprovação pra iniciar Fase 0

---

*Documentos completos disponíveis em `/home/ubuntu/pianolouvorja-flutter/.planning/`.
Qualquer dúvida, é só perguntar.*
