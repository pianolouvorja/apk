# LouvorJA PIANO Mobile

> App mobile (Flutter) para gerenciamento de cultos adventistas — versão
> simplificada do [LouvorJA PIANO Desktop](https://github.com/pianolouvorja/app).

[![CI](https://github.com/pianolouvorja/mobile/actions/workflows/ci.yml/badge.svg)](https://github.com/pianolouvorja/mobile/actions)
[![Coverage](https://img.shields.io/badge/coverage-≥90%25-brightgreen)]()
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter)]()

---

## O que é

O **LouvorJA PIANO Mobile** é o companion mobile do aplicativo desktop usado
por igrejas adventistas do sétimo dia (IASD) para gerenciar cultos. A versão
mobile é **simplificada** — focada no que um líder de culto, músico ou ancião
precisa no celular:

- **Hinos e coletâneas** — Hinário Adventista, Louvor JA, e mais
- **Letras offline** — baixe hinos favoritos e acesse sem internet
- **Liturgia do dia** — ordem do culto com itens e horários
- **Cronômetro** — contagem regressiva para cada item da liturgia
- **Escala de músicos** — quem está escalado para o sábado
- **Busca global** — encontre qualquer coisa em um toque

### O que NÃO está incluído (desktop-only)

Projeção multi-tela · FTP sync · Players de mídia · PPTX · Conversão de
apresentações · Detecção de monitores

---

## Stack

| Camada | Tecnologia |
|--------|-----------|
| Framework | Flutter 3.22+ / Dart 3.4+ |
| State management | flutter_bloc 8.1+ |
| HTTP | dio 5.4+ |
| Database | Drift (SQLite) 2.16+ |
| Routing | go_router 14+ |
| Serialization | freezed + json_serializable |
| i18n | easy_localization |
| Testing | flutter_test + bloc_test + mocktail |

---

## Estrutura do Projeto

```
pianolouvorja-flutter/
├── .planning/              ← Documentação agentica (você está aqui)
│   ├── SPEC.md             Requisitos funcionais e não-funcionais
│   ├── PLAN.md             Tasks detalhadas (7 fases, 30+ tasks)
│   ├── AGENTS.md           Guia para AI agents
│   ├── CONTEXT.md          Estado técnico + codebase de referência
│   ├── DESIGN-TOKENS.md    Tokens do design system web→Flutter
│   ├── API.md              Endpoints, schemas, auth da API LouvorJA
│   └── README.md           Este arquivo
├── lib/                    ← Código Flutter (a criar na Fase 0)
├── test/                   ← Testes unitários (a criar)
├── integration_test/       ← Testes E2E (a criar)
└── assets/                 ← Recursos estáticos (a criar)
```

---

## Documentação Agentica

Este projeto usa **Spec-Driven Development (SDD)** — todo o planejamento é
feito através de documentos estruturados antes de qualquer código.

| Documento | Função | Para quem |
|-----------|--------|-----------|
| **[SPEC.md](./SPEC.md)** | O QUE construir — requisitos, critérios de aceite, métricas | Product owner, devs, QA |
| **[PLAN.md](./PLAN.md)** | COMO construir — tasks bite-sized com verificação | Devs, AI agents |
| **[AGENTS.md](./AGENTS.md)** | REGRAS para agents — convenções, padrões, proibições | Claude Code, Codex, Cursor |
| **[CONTEXT.md](./CONTEXT.md)** | ONDE estamos — estado técnico, APIs, mapeamento desktop→mobile | Qualquer pessoa nova |
| **[DESIGN-TOKENS.md](./DESIGN-TOKENS.md)** | DESIGN — tokens extraídos do styleguide web, traduzidos para Flutter | Devs, designers |
| **[API.md](./API.md)** | API — endpoints, schemas, auth, retry (JSON estático atual + REST futura) | Devs |

---

## Roadmap

| Fase | Foco | Duração |
|------|------|---------|
| **0** | Setup do projeto + CI + design system | 2 sem |
| **1** | Fundação + Home + navegação | 3 sem |
| **2** | Catálogo de hinos + busca + sync offline | 4 sem |
| **3** | Liturgia do dia | 3 sem |
| **4** | Cronômetro + contagem regressiva | 2 sem |
| **5** | Escala de músicos | 2 sem |
| **6** | Busca global + polimento | 2 sem |
| **7** | Release (Google Play + App Store) | 3 sem |

**Total estimado:** ~21 semanas (5 meses) com 1 dev + IA

---

## Começando (quando implementação iniciar)

### Pré-requisitos

- Flutter SDK 3.22+
- Dart SDK 3.4+
- Android Studio (para Android)
- Xcode 15+ (para iOS, requer macOS)
- Um dispositivo real ou emulador

### Setup

```bash
# Clone (quando o repo existir)
git clone https://github.com/pianolouvorja/mobile.git
cd mobile

# Instale dependências
flutter pub get

# Gere código (freezed, drift, etc)
dart run build_runner build --delete-conflicting-outputs

# Rode em modo debug
flutter run
```

### Comandos essenciais

```bash
# Análise estática
flutter analyze --fatal-infos

# Testes com coverage
flutter test --coverage

# Build release
flutter build apk --release --split-per-abi   # Android
flutter build ipa --release                    # iOS
```

---

## Comparação: Desktop vs Mobile

| Feature | Desktop (Electron) | Mobile (Flutter) |
|---------|-------------------|------------------|
| Catálogo de hinos | ✅ Completo | ✅ **Sim** |
| Letras offline | ✅ Completo | ✅ **Sim** |
| Liturgia do dia | ✅ Completo | ✅ **Sim** |
| Cronômetro | ✅ Completo | ✅ **Sim** |
| Escala de músicos | ✅ Completo | ✅ **Sim** |
| Busca global | ✅ Completo | ✅ **Sim** |
| Configurações | ✅ Completo | ✅ **Sim** |
| Projeção multi-tela | ✅ Completo | ❌ Não (desktop) |
| Player YouTube | ✅ Completo | ❌ Não (v2) |
| Player mídia local | ✅ Completo | ❌ Não (desktop) |
| FTP sync | ✅ Completo | ❌ Não (desktop) |
| Conversão PPTX | ✅ Completo | ❌ Não (desktop) |
| Detecção monitores | ✅ Completo | ❌ Não (desktop) |
| Bíblia integrada | ✅ Completo | ❌ Não (v2) |
| Sorteio de hinos | ✅ Completo | ❌ Não (v2) |

---

## Estado do Projeto

**Atual:** Planejamento completo (5 documentos agenticos criados).

**Próximos passos:**
1. Confirmar com Ezequias: endpoints de API, formato do catálogo, marca
2. Criar repo `pianolouvorja/mobile` na org GitHub
3. Executar Fase 0 do PLAN.md (setup do projeto Flutter)

---

## Créditos

| Pessoa | Função |
|--------|--------|
| **Ezequias Fonseca** | Mantenedor do LouvorJA, idealizador do app |
| **Rafael Zendron** | Planejamento mobile, implementação |

---

## Licença

MIT — alinhado com os demais projetos da organização `pianolouvorja`.
