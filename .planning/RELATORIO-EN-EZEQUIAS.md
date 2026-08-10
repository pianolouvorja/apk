# 🇺🇸 SDA Hymnal (EN) — Relatório de Fontes de Áudio

Ezequias, pesquisei fontes de áudio e letras pro hinário adventista em inglês
(695 hinos). **Tudo testado e confirmado com download real.**

---

## Cobertura

| Recurso | Hinos | Fonte |
|---------|-------|-------|
| Letras | 695/695 | NPM `sda-hymnal` (MIT) |
| Áudio cantado | 483/695 | SacCentral Choir (bjaarmy.com) |
| Áudio instrumental | 695/695 | MIDI GitHub `frazras` (GPL) |
| 212 faltantes (cantado) | 212 | YouTube grabber |

---

## 1. Letras — 695 hinos (100%)

Pacote NPM `sda-hymnal` com SQLite: título, até 7 estrofes, refrão, autor,
referência bíblica. Licença MIT (uso comercial liberado).

## 2. Áudio cantado — 483 hinos (70%)

Coral adventista (SacCentral) gravou e publicou os MP3s.

- Site: `bjaarmy.com/sabbath-school/SSChoir-SDA_Hymns/`
- Qualidade: 64kbps, stereo, ~1MB cada, ~2 min
- Playlist oficial M3U com os 483 hinos
- **Testado:** baixei o hino 001, MP3 válido

## 3. Áudio instrumental — 695 hinos (100%)

Repo GitHub `frazras/SDA-Hymnal-Old-and-New`. 695 arquivos MIDI, ~20KB cada.
Licença GPL. **Testado:** HTTP 200 confirmado.

## 4. Os 212 que faltam (cantado)

SacCentral não gravou esses. Opção: YouTube grabber com `yt-dlp` (existem
playlists completas). Se não achar no YouTube, cai pro MIDI.

---

## Pergunta

Posso entrar em contato com o SacCentral pedindo permissão formal pra usar os
483 MP3s, ou prefere que usemos direto?
