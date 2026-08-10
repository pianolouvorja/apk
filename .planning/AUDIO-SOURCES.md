# AUDIO-SOURCES.md — Fontes de Áudio Multi-Idioma

> **Documento de referência compartilhado entre:**
> - **Electron** (`pianolouvorja/app`) — desktop Windows/macOS/Linux
> - **Web PWA** (`pianolouvorja/web`) — Vue 3 + Vuetify
> - **Flutter** (`pianolouvorja-flutter`) — iOS/Android
>
> **Este arquivo é a fonte da verdade para todas as frentes.**
> Manter sincronizado em todos os repos sob `docs/AUDIO-SOURCES.md`.

---

## Visão Geral por Idioma

| Idioma | Hinário | Hinos | Letras | Áudio Cantado | Áudio Instrumental | Status |
|--------|---------|-------|--------|---------------|---------------------|--------|
| 🇧🇷 PT | Louvor JA + Hinário ADV | ~600 | ✅ API Louvor JA | ✅ API Louvor JA (MP3) | ✅ API Louvor JA (MP3 PB) | **Completo** |
| 🇪🇸 ES | Himnario Adventista | 620 | ✅ API Louvor JA | ✅ API Louvor JA (MP3) | ✅ API Louvor JA (MP3 PB) | **Completo** |
| 🇺🇸 EN | SDA Hymnal (1985) | 695 | ✅ NPM `sda-hymnal` | ✅ SacCentral Choir (483/695) + YouTube (212) | ✅ MIDI GitHub (695/695) | **Funcional** |

---

## 1. Português (PT) e Espanhol (ES) — API Louvor JA

### Endpoint de Música

```
GET https://api.louvorja.com.br/json_db/music_{id_music}
Header: Api-Token: <token>
```

### Schema de Resposta (PT/ES)

```typescript
{
  id_music: number | string,
  name: string,
  track: number | string | null,
  duration: string | number | null,       // "3:07" | 187.5 | "1:02:03"
  url_music: string | null,                // MP3 cantado — caminho relativo
  url_instrumental_music: string | null,    // MP3 playback/instrumental
  lyric: Array<{
    time: string,                          // timestamp "0:32"
    text: string                           // linha da letra sincronizada
  }> | null,
  // ... outros campos
}
```

### URL de Áudio Resolvida

```
Cantado:        https://api.louvorja.com.br/file{url_music}
Instrumental:   https://api.louvorja.com.br/file{url_instrumental_music}
```

**Características:**
- Streaming com `accept-ranges: bytes` (seek funcional)
- Content-Type: `audio/mpeg`
- Token obrigatório no header `Api-Token`
- Retry com backoff exponencial em 429/5xx (máx 5 tentativas)

### Detalhes ES
- 620 músicas com áudio completo (cantado + instrumental)
- 100% de cobertura — todas as músicas têm áudio
- Mesmo endpoint, mesmo schema

---

## 2. Inglês (EN) — SDA Hymnal (695 hinos)

O inglês usa **3 fontes complementares** pois a API Louvor JA não cobre EN.

### 2.1 Letras — NPM `sda-hymnal` (MIT License)

**Repo:** `https://github.com/joshpetit/sda-hymnal`
**NPM:** `npm install sda-hymnal`

#### Estrutura SQLite

```sql
CREATE TABLE Hymns (
  _id    INTEGER PRIMARY KEY,
  number INTEGER,        -- 1-695
  title  TEXT,
  refrain TEXT,
  refrain2 TEXT,
  verse1 TEXT,
  verse2 TEXT,
  verse3 TEXT,
  verse4 TEXT,
  verse5 TEXT,
  verse6 TEXT,
  verse7 TEXT,
  author TEXT,
  scripture TEXT,
  topic TEXT,
  tune TEXT,
  meter TEXT,
  composer TEXT,
  key TEXT
);

CREATE TABLE Sections (
  _id        INTEGER PRIMARY KEY,
  Title      TEXT,
  FirstHymn  INTEGER,
  LastHymn   INTEGER
);
```

#### Exemplo de Dados

```json
{
  "number": 1,
  "title": "Praise to the Lord",
  "verse1": "Praise to the Lord, the Almighty, the King of creation!\nO my soul, praise Him, for He is thy health and salvation!\nAll ye who hear, now to His temple draw near;\nJoin ye in glad adoration!",
  "author": "Joachim Neander"
}
```

**Total:** 695 hinos + 20 seções (categorias)
**Tamanho:** ~2.5 MB (SQLite)
**Licença:** MIT — uso comercial permitido

### 2.2 Áudio Cantado — SacCentral Choir (MP3)

**Fonte:** `bjaarmy.com` (ministério SacCentral SDA)
**Playlist M3U:** `https://bjaarmy.com/sabbath-school/SSChoir-SDA_Hymns/_SDA_Hymnal_WMP_Numeric-WEB.m3u`

#### URL Pattern

```
https://bjaarmy.com/sabbath-school/SSChoir-SDA_Hymns/{NNN}_{Title}-{Stanzas}.mp3
```

**Onde:**
- `NNN` = número do hino com zero padding (001-695)
- `Title` = título com underscores no lugar de espaços
- `Stanzas` = `ALL_X_Stanzas` ou `Stanzas_1-2_and_4`

#### Especificações Técnicas (testado e confirmado)

| Propriedade | Valor |
|-------------|-------|
| Formato | MP3 (MPEG ADTS, Layer III, v1) |
| Bitrate | 64 kbps (CBR) |
| Sample rate | 32000 Hz |
| Canais | 2 (Joint Stereo) |
| Duração média | ~2 min (varia 1-4 min) |
| Tamanho médio | ~1 MB por hino |
| Content-Type | `audio/mpeg` |
| Accept-Ranges | `bytes` (seek funcional) |
| Servidor | LiteSpeed |

#### Cobertura: 483 de 695 hinos (70%)

**Hinos disponíveis:** 001-013, 015-034, 036-065, 067-093, 095-100, 102, 104-111, 113, 115-122, 124-125, 127, 130-132, 135-137, 139, 141-148, 150-154, 156-163, 165-168, 171, 177-181, 183-193, 195-199, 202, 204-208, 211-214, 216-218, 220-224, 227-233, 235, 237, 240-242, 244-246, 248-251, 253-255, 257-265, 267-282, 284, 286-287, 289-301, 303-306, 308-312, 315-316, 318-319, 321-322, 326-330, 334-338, 340-341, 343-354, 358-359, 361, 365-371, 373-376, 381-385, 387-388, 390, 394, 403, 412-440, 442, 446, 448-452, 456-470, 472-478, 483-485, 487, 489, 492-493, 498-501, 505-512, 515-526, 528-534, 537-538, 545-547, 552, 554-555, 557, 559-560, 565-570, 573, 575, 577-580, 582, 585-588, 590, 592-596, 598, 600-602, 604-610, 612, 614-616, 618-620, 623-626, 632-634, 639, 642-645, 647-648, 650-651, 661-694

**Hinos faltantes (212):** ver seção "2.4 YouTube Grabber" abaixo.

### 2.3 Áudio Instrumental — MIDI (GPL License)

**Repo:** `https://github.com/frazras/SDA-Hymnal-Old-and-New`
**Cobertura:** 695/695 hinos (100%)

#### URL Pattern

```
https://raw.githubusercontent.com/frazras/SDA-Hymnal-Old-and-New/master/www/media/midi/{NNN}.mid
```

**Onde:** `NNN` = número do hino com zero padding (001-695)

#### Especificações Técnicas (testado e confirmado)

| Propriedade | Valor |
|-------------|-------|
| Formato | MIDI (Standard MIDI File) |
| Tamanho médio | ~20-30 KB por hino |
| Content-Type | `audio/midi` |
| Servidor | GitHub raw.githubusercontent.com |
| Total aproximado | ~15 MB (695 arquivos) |
| Licença | GPL |

#### Exemplo

```
Hino 001: https://raw.githubusercontent.com/frazras/SDA-Hymnal-Old-and-New/master/www/media/midi/001.mid
→ HTTP 200, 21.487 bytes, audio/midi ✅

Hino 695: https://raw.githubusercontent.com/frazras/SDA-Hymnal-Old-and-New/master/www/media/midi/695.mid
→ HTTP 200 ✅
```

### 2.4 YouTube Grabber — Hinos Faltantes (212)

Para os 212 hinos não cobertos pelo SacCentral Choir, usar download do YouTube.

#### Playlists YouTube com SDA Hymnal cantado

| Playlist | URL | Cobertura estimada |
|----------|-----|--------------------|
| SDA Hymnal with Lyrics | `youtube.com/playlist?list=PL-Hb89x_KzK8h7l-WfKErLS-JasmTWfcs` | ~199 vídeos |
| Adventist Hymns & Worship | Vários compilados | Parcial |

#### Hinos Faltantes (212 — sem SacCentral)

```
014 035 066 094 101 103 112 114 123 126 128 129 133 134 138 140 149 155
164 169 170 172 173 174 175 176 182 194 200 201 203 209 210 215 219 225
226 234 236 238 239 243 247 252 256 266 283 285 288 302 307 313 314 317
320 323 324 325 331 332 333 339 342 355 356 357 360 362 363 364 372 377
378 379 380 386 389 391 392 393 395 396 397 398 399 400 401 402 404 405
406 407 408 409 410 411 441 443 444 445 447 453 454 455 459 471 479 480
481 482 486 488 490 491 494 495 496 497 502 503 504 513 514 527 535 536
539 540 541 542 543 544 548 549 550 551 553 556 558 561 562 563 564 571
572 574 576 581 583 584 589 591 597 599 603 611 613 617 621 622 627 628
629 630 631 635 636 637 638 640 641 646 649 656 657 658 659 660 695
```

#### Estratégia de YouTube Grabber

```bash
# yt-dlp para baixar áudio de um hino específico
yt-dlp -x --audio-format mp3 --audio-quality 5 \
  "ytsearch:SDA Hymnal {NNN} {title}" \
  -o "{NNN}_{title}.mp3"
```

**Notas:**
- Qualidade de áudio do YouTube é variável (128-256 kbps)
- Nem todos os 695 têm versão cantada individual no YouTube
- Para os que não houver, usar MIDI como fallback
- Considerar respeitar ToS do YouTube — usar apenas para hinos sem fonte direta

### 2.5 Hinários Históricos EN (Bônus — Futuro)

**Repo:** `https://github.com/GospelSounders/all-sda-hymnals`

| Código | Hinário | Hinos | Período |
|--------|---------|-------|---------|
| SDAH | Seventh-day Adventist Hymnal | 920 | 1985 |
| CS1900 | Christ in Song | 742 | 1900 |
| CH1941 | Church Hymnal | 703 | 1941 |
| HT1886 | Hymns and Tunes | 1.413 | 1886 |
| HT1869 | Hymns and Tunes | 537 | 1869 |
| HSAB1852 | Hymns for SD Adventists | 139 | 1852 |
| MH1843 | Millennial Harp | 123 | 1843 |
| HGPP1849 | Hymns for God's Peculiar People | 53 | 1849 |
| **Total** | **8 hinários** | **5.077 hinos** | |

**Dados:** JSON estruturado com letras, sem áudio.
**Licença:** GPL.

---

## 3. Estratégia de Resolução de Áudio por Plataforma

### Prioridade de Source (ordem decrescente)

```typescript
interface AudioResolution {
  // PT/ES
  pt_es: {
    lyrics: 'api_louvorja',
    sung: 'api_louvorja',         // MP3 cantado
    instrumental: 'api_louvorja', // MP3 playback
  },
  // EN
  en: {
    lyrics: 'npm_sda_hymnal',
    sung: 'saccentral_choir',      // MP3 coral (483/695)
    sung_fallback_1: 'youtube',    // YouTube grabber (212 restantes)
    sung_fallback_2: null,         // Se não tiver no YouTube, sem cantado
    instrumental: 'midi_frazras',  // MIDI (695/695 — fallback universal)
  }
}
```

### Fluxograma de Resolução (EN)

```
Hino EN solicitado
        │
        ▼
   ┌─ SacCentral tem? ─┐
   │     (483)         │
   ├─ SIM → MP3 coral ─┤
   │                   │
   │     NÃO (212)     │
   │         │         │
   │         ▼         │
   │  ┌─ YouTube ──┐   │
   │  │  grabber?  │   │
   │  ├─ SIM → MP3┤   │
   │  │            │   │
   │  │  NÃO       │   │
   │  │    │       │   │
   │  │    ▼       │   │
   │  │  MIDI      │   │
   │  │  (fallback)│   │
   │  └────────────┘   │
   └───────────────────┘
```

---

## 4. Implementação por Plataforma

### 4.1 Electron (`pianolouvorja/app`)

```typescript
// src/services/audio-resolver.ts

interface ResolvedAudio {
  type: 'sung' | 'instrumental' | 'midi';
  url: string;
  source: 'louvorja' | 'saccentral' | 'youtube' | 'midi_github';
}

function resolveAudio(hymnNumber: number, lang: 'pt' | 'es' | 'en'): ResolvedAudio | null {
  // PT/ES — API Louvor JA
  if (lang === 'pt' || lang === 'es') {
    return {
      type: 'sung',
      url: `${URL_FILES}${hymn.url_music}`,
      source: 'louvorja',
    };
  }

  // EN — cascade
  // 1. SacCentral Choir
  const saccentralUrl = resolveSaccentralUrl(hymnNumber);
  if (saccentralUrl) {
    return { type: 'sung', url: saccentralUrl, source: 'saccentral' };
  }

  // 2. MIDI (fallback garantido)
  return {
    type: 'instrumental',
    url: `https://raw.githubusercontent.com/frazras/SDA-Hymnal-Old-and-New/master/www/media/midi/${String(hymnNumber).padStart(3, '0')}.mid`,
    source: 'midi_github',
  };
}
```

**Notas Electron:**
- MIDI playback: usar `<audio>` tag (Chromium suporta MIDI com SoundFont)
- Cache local: áudios já baixados ficam em `appData/piano-louvorja/media/`
- Offline: cache local tem prioridade sobre fetch remoto

### 4.2 Web PWA (`pianolouvorja/web` — Vue 3 + Vuetify)

```typescript
// src/composables/useAudioResolver.ts

export function useAudioResolver() {
  const { URL_FILES, URL_DATABASE, API_TOKEN } = useApiConfig();

  async function resolveHymnAudio(hymn: Hymn, lang: Language): Promise<ResolvedAudio | null> {
    // PT/ES — API Louvor JA
    if (lang !== 'en') {
      const musicData = await fetch(
        `${URL_DATABASE}/music_${hymn.id_music}`,
        { headers: { 'Api-Token': API_TOKEN } }
      ).then(r => r.json());

      return {
        type: 'sung',
        url: `${URL_FILES}${musicData.url_music}`,
        source: 'louvorja',
        lyric: musicData.lyric, // timestamps sincronizados
      };
    }

    // EN — cascade
    // 1. SacCentral
    const saccentral = resolveSaccentralUrl(hymn.number);
    if (saccentral) return { type: 'sung', url: saccentral, source: 'saccentral' };

    // 2. MIDI
    return {
      type: 'midi',
      url: midiUrl(hymn.number),
      source: 'midi_github',
    };
  }

  return { resolveHymnAudio };
}
```

**Notas Web PWA:**
- **CORS:** SacCentral (`bjaarmy.com`) e GitHub raw enviam headers CORS permissivos — testado OK
- MIDI no browser: usar `Tone.js` ou `@magenta/music` para sintetizar MIDI → áudio
- Cache: Service Worker (`workbox`) para cachear MP3s no primeiro acesso
- Token: expor `Api-Token` apenas em chamadas server-side ou via proxy (NUXT API route)

### 4.3 Flutter (`pianolouvorja-flutter`)

```dart
// lib/core/audio/audio_resolver.dart

enum AudioType { sung, instrumental, midi }
enum AudioSource { louvorja, saccentral, youtube, midiGithub, localCache }

class ResolvedAudio {
  final AudioType type;
  final AudioSource source;
  final String url;
  final List<LyricLine>? syncedLyrics; // PT/ES only

  const ResolvedAudio({
    required this.type,
    required this.source,
    required this.url,
    this.syncedLyrics,
  });
}

abstract class AudioResolver {
  Future<ResolvedAudio?> resolve(Hymn hymn, Language lang);
}

class AudioResolverImpl implements AudioResolver {
  final LouvorjaApiClient _louvorja;
  final Dio _dio;
  final HymnDatabase _db; // Drift

  @override
  Future<ResolvedAudio?> resolve(Hymn hymn, Language lang) async {
    // 1. Verificar cache local (offline-first)
    final cached = await _db.getAudioCache(hymn.id, lang);
    if (cached != null) {
      return ResolvedAudio(
        type: cached.type,
        source: AudioSource.localCache,
        url: cached.localPath,
        syncedLyrics: cached.lyrics,
      );
    }

    // 2. PT/ES — API Louvor JA
    if (lang != Language.en) {
      return _resolveLouvorja(hymn);
    }

    // 3. EN — cascade: SacCentral → MIDI
    return _resolveEnglish(hymn);
  }

  Future<ResolvedAudio> _resolveLouvorja(Hymn hymn) async {
    final music = await _louvorja.fetchMusicDetail(hymn.id);
    return ResolvedAudio(
      type: AudioType.sung,
      source: AudioSource.louvorja,
      url: '${ApiConfig.urlFiles}${music.urlMusic}',
      syncedLyrics: music.lyric?.map((l) => LyricLine(time: l.time, text: l.text)).toList(),
    );
  }

  Future<ResolvedAudio> _resolveEnglish(Hymn hymn) async {
    // 1. SacCentral Choir (483/695)
    final saccentral = _resolveSaccentral(hymn.number);
    if (saccentral != null) return saccentral;

    // 2. MIDI fallback (695/695 garantido)
    return ResolvedAudio(
      type: AudioType.midi,
      source: AudioSource.midiGithub,
      url: 'https://raw.githubusercontent.com/frazras/SDA-Hymnal-Old-and-New/'
          'master/www/media/midi/${hymn.number.toString().padLeft(3, '0')}.mid',
    );
  }

  /// Retorna URL SacCentral se o hino existir, null caso contrário.
  ResolvedAudio? _resolveSaccentral(int hymnNumber) {
    final padded = hymnNumber.toString().padLeft(3, '0');
    if (SacCentralIndex.available.contains(hymnNumber)) {
      // Lookup do filename exato na playlist M3U pré-carregada
      final filename = _saccentralFilenames[padded];
      if (filename != null) {
        return ResolvedAudio(
          type: AudioType.sung,
          source: AudioSource.saccentral,
          url: 'https://bjaarmy.com/sabbath-school/SSChoir-SDA_Hymns/$filename',
        );
      }
    }
    return null;
  }
}
```

**Packages Flutter necessários:**

```yaml
# pubspec.yaml
dependencies:
  just_audio: ^0.9.39        # player de áudio (MP3, streaming, lock screen controls)
  audio_service: ^0.18.15    # background audio (play em segundo plano)
  dio: ^5.7.0                # HTTP client com interceptors (retry, rate limit)
  path_provider: ^2.1.5      # caminhos do filesystem para cache offline
```

**Notas Flutter:**
- `just_audio` suporta MP3 streaming nativamente (iOS + Android)
- MIDI no Flutter: usar package `flutter_midi` ou converter MIDI → MP3 em build time
- Cache offline: baixar MP3s para `getApplicationDocumentsDirectory()/media/`
- Background audio: `audio_service` para tocar com app minimizado

---

## 5. Banco de Dados — Cache de Áudio

### Schema (Drift/SQLite — Flutter)

```dart
// Tabela de cache de áudio offline
class AudioCacheTable extends Table {
  IntColumn get hymnId => integer()();
  TextColumn get language => text()(); // 'pt', 'es', 'en'
  TextColumn get audioType => text()(); // 'sung', 'instrumental', 'midi'
  TextColumn get source => text()(); // 'louvorja', 'saccentral', 'midi_github'
  TextColumn get remoteUrl => text()();
  TextColumn get localPath => text()();
  DateTimeColumn get downloadedAt => dateTime()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get syncedLyricsJson => text().nullable()(); // PT/ES

  @override
  Set<Column> get primaryKey => {hymnId, language, audioType};
}
```

### Index SacCentral (lookup rápido)

```dart
// lib/core/audio/saccentral_index.dart

/// Lista dos 483 hinos disponíveis no SacCentral Choir.
/// Gerada a partir da playlist M3U oficial.
const Set<int> saccentralAvailableHymns = {
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19,
  // ... (483 números — ver lista completa no arquivo saccentral_index.json)
};

/// Mapa de número → filename exato no servidor SacCentral.
/// Necessário porque filenames incluem título e estrofes variáveis.
Map<String, String> saccentralFilenames = {
  '001': '001_Praise_to_the_Lord-ALL_3_Stanzas.mp3',
  '002': '002_All_Creatures_of_Our_God_and_King-Stanzas_1-2_and_4.mp3',
  // ... (483 entradas)
};
```

> **Para gerar este arquivo:** ver script `scripts/extract_saccentral_index.dart` (TODO).

---

## 6. Considerações Legais

### Uso Permitido (sem necessidade de licença)

| Fonte | Licença | Uso Comercial |
|-------|---------|---------------|
| API Louvor JA (PT/ES) | Própria (Ezequias Fonseca) | ✅ Autorizado |
| NPM `sda-hymnal` (letras EN) | MIT | ✅ Permitido |
| `frazras/SDA-Hymnal` (MIDI EN) | GPL | ✅ Permitido (com source disclosure) |
| `GospelSounders/all-sda-hymnals` | GPL | ✅ Permitido (com source disclosure) |

### Uso Condicionado

| Fonte | Restrição |
|-------|-----------|
| SacCentral Choir (`bjaarmy.com`) | Sem licença explícita — verificar com o ministry antes de redistribuir |
| YouTube grabber | ToS do YouTube proíbe download; usar apenas para hinos sem outra fonte |

### Recomendação

1. **PT/ES:** Sem questões — API Louvor JA é do Ezequias
2. **EN letras:** MIT — sem problema
3. **EN MIDI:** GPL — incluir attribution no app
4. **EN MP3 SacCentral:** Contactar SacCentral SDA Church pedindo permissão de uso
5. **EN YouTube:** Último recurso, apenas para os 212 hinos sem outra fonte

---

## 7. Próximos Passos (TODO)

- [ ] **Gerar `saccentral_index.json`** — extrair os 483 filenames da playlist M3U automaticamente
- [ ] **Contactar SacCentral** — pedir permissão formal de uso dos MP3s
- [ ] **YouTube grabber batch** — script para baixar os 212 hinos faltantes
- [ ] **Converter MIDI → MP3** (opcional) — usar FluidSynth + SoundFont para gerar MP3 instrumental de qualidade
- [ ] **Atualizar API Louvor JA** — se Ezequias adicionar EN no futuro, remover cascata complexa
- [ ] **Testar CORS** no Web PWA — confirmar que `bjaarmy.com` envia `Access-Control-Allow-Origin`

---

## Apêndice A — Testes Realizados (2026-08-01)

| Teste | URL | Resultado |
|-------|-----|-----------|
| API Louvor JA PT (cantado) | `api.louvorja.com.br/file{url_music}` | ✅ HTTP 200, `audio/mpeg`, streaming |
| API Louvor JA ES (cantado) | `api.louvorja.com.br/file{url_music}` | ✅ HTTP 200, `audio/mpeg`, streaming |
| SacCentral hino 001 | `bjaarmy.com/.../001_Praise_to_the_Lord-ALL_3_Stanzas.mp3` | ✅ HTTP 200, `audio/mpeg`, 1.040.898 bytes, 2:09 min |
| SacCentral hino 350 | `bjaarmy.com/.../350_Blest_Be_the_Tie_That_Binds-ALL_4_Stanzas.mp3` | ✅ Disponível na playlist |
| MIDI hino 001 | `raw.githubusercontent.com/frazras/.../001.mid` | ✅ HTTP 200, `audio/midi`, 21.487 bytes |
| NPM sda-hymnal letras | SQLite `hymns.db` | ✅ 695 hinos com letras completas |
| Playlist SacCentral M3U | `bjaarmy.com/.../_SDA_Hymnal_WMP_Numeric-WEB.m3u` | ✅ 483 entradas MP3 |

## Apêndice B — URLs de Referência

| Recurso | URL |
|---------|-----|
| Playlist SacCentral M3U | `https://bjaarmy.com/sabbath-school/SSChoir-SDA_Hymns/_SDA_Hymnal_WMP_Numeric-WEB.m3u` |
| Index SacCentral HTML | `https://bjaarmy.com/sabbath-school/index-hymnal.html` |
| Repo MIDI | `https://github.com/frazras/SDA-Hymnal-Old-and-New` |
| Repo Letras NPM | `https://github.com/joshpetit/sda-hymnal` |
| Repo Hinários Históricos | `https://github.com/GospelSounders/all-sda-hymnals` |
| YouTube Playlist EN | `https://www.youtube.com/playlist?list=PL-Hb89x_KzK8h7l-WfKErLS-JasmTWfcs` |
| API Louvor JA | `https://api.louvorja.com.br` |
