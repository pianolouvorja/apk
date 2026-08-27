# Deploy — LouvorJA PIANO Mobile (Flutter / APK)

Fluxo Git + CI para publicar uma nova versão do **app Android**. O GitHub Actions **valida** o código (analyze, test, build debug). O **APK de release** é gerado **localmente**. A GitHub Release deste repo publica **notes + o APK** — é isso que dispara o banner de auto-update no app.

Repo: `github.com/pianolouvorja/apk`  
Pacote: `louvorja_piano_mobile`  
Fonte da versão: `pubspec.yaml` → campo `version`

**Diferença do WEB:** na web a hospedagem publica a partir do Git; a Release é só notes.  
**Diferença do ELECTRON:** no desktop sobem AppImage + `.exe`. Aqui o artefato é **um APK**. Não há Hostinger. Quem já tem o app instalado recebe a atualização pelo `UpdateService` (consulta `https://api.github.com/repos/pianolouvorja/apk/releases/latest`).

Esta pasta `docs/` é **local** (está no `.gitignore`). Não sobe para o repositório.

---

## Regras de branch (obrigatório)

| Branch | Quem pode atualizar | Como |
|--------|---------------------|------|
| `feat/*`, `fix/*`, `chore/*` | Direto (push) | Trabalho diário |
| `staging` | **Somente via PR** | Feature, fix e bump de versão |
| `main` | **Somente via PR a partir de `staging`** | Release de produção |

- Nunca commit/push direto em `staging` ou `main`.
- `main` **só** recebe PR com origem `staging`.
- Features novas nunca vão direto para `main`.
- Produção Git (`main`) só recebe o que já passou pela `staging`.

## Ambientes / artefatos

| Etapa | O que acontece |
|-------|----------------|
| PR para `staging` ou `main` | CI: `flutter analyze`, `flutter test`, `flutter build apk --debug` (quando o workflow incluir a branch) |
| Push/PR na `main` | CI atual (`.github/workflows/ci.yml`) |
| Build local release | `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk` |
| GitHub Release na tag `vX.Y.Z` | Notes + upload do APK → banner de update nos aparelhos |

URLs úteis:

- Releases: https://github.com/pianolouvorja/apk/releases
- Actions CI: https://github.com/pianolouvorja/apk/actions/workflows/ci.yml
- Compare PRs: https://github.com/pianolouvorja/apk/compare

> **CI hoje:** o workflow dispara em **push/PR para `main`** (e `master`). PRs para `staging` podem não ter Quality Gate até o `ci.yml` incluir `staging`. Mesmo assim o fluxo Git abaixo é obrigatório. Quando atualizar o workflow, acrescente `staging` em `on.push.branches` e `on.pull_request.branches`.

## Fluxo correto (obrigatório)

```text
feat/* ou fix/*
    →  valida local (analyze + test + run/emulador)
    →  PR → staging
    →  CI (quando houver) + merge
    →  branch chore/version-X.Y.Z a partir de staging
    →  versionamento (bump no pubspec + tag)
    →  PR → staging
    →  merge
    →  PR staging → main
    →  CI + merge
    →  build APK release (local)
    →  GitHub Release na tag (notes + APK)
    →  aparelhos veem o banner de atualização
```

1. Trabalhe em branch de atuação (`feat/...`, `fix/...`) criada a partir da `staging` atualizada.
2. Valide localmente **antes** de mergear.
3. Abra PR **atuação → `staging`**. Merge só com revisão (e CI verde, se estiver rodando).
4. Com o pacote pronto na `staging`, faça o **bump de versão** em `chore/version-X.Y.Z` (não em cada feat).
5. PR **`chore/version-*` → `staging`**. Merge.
6. Abra PR **`staging` → `main`**. Merge.
7. Gere o **APK release** localmente e publique a **GitHub Release** com o APK na tag criada no bump.

Não faça push direto na `main` com features novas.

---

## Onde entra o versionamento

O bump **não** acontece em cada `feat`/`fix`. Ele marca o pacote que já está na `staging` e vai para `main`.

```text
trabalho diário                 release
───────────────                 ───────
feat/fix → staging  →  bump (chore/version) → staging  →  staging → main  →  Release + APK
```

| Momento | Versiona? | Release + APK? | Por quê |
|---------|-----------|----------------|---------|
| Branch `feat`/`fix` | Não | Não | Trabalho em andamento |
| Merge na `staging` (feature) | Não | Não | Só consolida para testar |
| Staging com o pacote pronto | **Sim** (branch `chore/version-*`) | Não ainda | Congela versão + cria tag `vX.Y.Z` |
| PR / merge na `main` | Não (já versionou) | Não ainda | Produção Git recebe a versão |
| Após merge na `main` | Não | **Sim** | Publica notes + APK; auto-update liga |

Como `staging` é protegida, o bump **não** é push direto nela: use branch `chore/version-X.Y.Z` + PR.

A UI (splash, configurações) lê a versão em runtime via `AppVersion` / `package_info_plus`. **Não hardcodar** versão em widgets. O Android usa o mesmo valor:

```text
pubspec.yaml          Android
────────────          ───────
version: 0.1.1+2  →  versionName = 0.1.1
                     versionCode = 2
```

O `UpdateService` compara só o `versionName` (`0.1.1`) com a tag GitHub `v0.1.1` (sem o `+2`).

### Qual tipo de bump (SemVer)

Edite **somente** `pubspec.yaml` (`version:`). Sempre **incremente o `+N`** (versionCode). Sem o `+N` o Android fica em `versionCode` 1 e o APK novo pode recusar instalar por cima.

Versão atual de referência: `0.1.0` (trate o próximo release como `0.1.1+2` se ainda não houver `+N`).

| Situação | O que mudar | Exemplo | Tag Git |
|----------|-------------|---------|---------|
| Correção / ajuste pequeno | PATCH + `+N` | `0.1.0` → `0.1.1+2` | `v0.1.1` |
| Nova funcionalidade compatível | MINOR + `+N` | `0.1.1+2` → `0.2.0+3` | `v0.2.0` |
| Quebra / primeira estável | MAJOR + `+N` | `0.2.0+3` → `1.0.0+4` | `v1.0.0` |

A tag é `v` + versionName. **Não** coloque o `+N` na tag. Use `X.Y.Z` limpo (sem `-alpha`): o comparador do auto-update só entende números separados por ponto.

## Onde entram release notes e o APK

- A **tag** nasce no versionamento (`chore/version-*`).
- O **APK** nasce no build local **depois** do merge na `main`.
- A Release final deve ter:
  - notas da versão
  - **Android:** `app-release.apk` (pode renomear para `louvorja-piano-X.Y.Z.apk`)

O banner “Nova versão disponível” só aparece quando a Release **latest** no GitHub tem um asset `.apk` e a tag é **maior** que a versão instalada.

**Assinatura:** sem `android/key.properties` o Gradle usa a chave **debug** (ok para testar / sideload). Play Store e updates confiáveis no aparelho pedem keystore de upload — o arquivo fica fora do Git (`android/.gitignore` já ignora `key.properties` e `*.jks`).

---

## Exemplo completo (comandos)

Cenário: correção (patch). Raiz do repo:

```bash
cd /home/Arquivos/AmbienteDev/Projetos/Web/LouvorJA/StackFlutter/apk

export PATH="/home/Arquivos/AmbienteDev/SDKs/flutter/bin:$PATH"
export ANDROID_HOME="/home/Arquivos/AmbienteDev/SDKs/android"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
```

Troque `0.1.1` / `+2` / `fix/minha-alteracao` pelos valores reais do ciclo.

### 1. Atualizar a `staging` e criar a branch de atuação

```bash
git fetch origin
git switch staging
git pull origin staging

git switch -c fix/minha-alteracao
```

Nunca crie a branch a partir da `main` se o trabalho ainda não passou pelo staging.

### 2. Alterações, commit e push

```bash
# ... edite os arquivos ...

git add .
git commit -m "$(cat <<'EOF'
fix: descreva o motivo da alteração

EOF
)"

git push -u origin HEAD
```

### 3. Validar localmente

Ainda na branch de atuação, **antes** do merge na `staging`:

```bash
flutter pub get
flutter analyze --fatal-infos
flutter test
```

Smoke no emulador (opcional, mas recomendado):

```bash
flutter emulators --launch louvorja_pixel
flutter run
```

Build debug (o CI também faz isso; não gera o APK de loja):

```bash
flutter build apk --debug
```

**Não** é obrigatório `flutter build apk --release` nesta etapa; o APK de publicação vem no passo 9.

### 4. Abrir PR → `staging`

```bash
gh pr create --base staging --title "fix: descreva o motivo da alteração" --body "$(cat <<'EOF'
## Summary
- O que mudou e por quê

## Test plan
- [ ] Validado localmente (`flutter analyze` + `flutter test`)
- [ ] Smoke no emulador (`flutter run`)
- [ ] CI passou (se a PR disparar o workflow)
- [ ] Após merge, comportamento ok na staging

EOF
)"
```

Navegador: `https://github.com/pianolouvorja/apk/compare/staging...fix/minha-alteracao`

Se o `gh` falhar com `must be a collaborator`, abra pelo link acima.

### 5. Mergear a PR → `staging`

1. No GitHub, revise e faça **Merge** na `staging` (validação local ok; CI verde quando existir).
2. Confirme no remoto:

```bash
git fetch origin
git log --oneline -5 origin/staging
```

A branch `fix/minha-alteracao` pode ser apagada depois.

### 6. Versionar (branch `chore/version-*` → PR → `staging`)

Troque `0.1.1+2` pela próxima versão (SemVer da tabela acima).

```bash
git fetch origin
git switch -c chore/version-0.1.1 origin/staging
```

Edite `pubspec.yaml`:

```yaml
# antes
version: 0.1.0

# depois (exemplo de patch)
version: 0.1.1+2
```

```bash
git add pubspec.yaml
git commit -m "$(cat <<'EOF'
chore: versão 0.1.1+2

EOF
)"

git tag v0.1.1
git push -u origin HEAD --follow-tags
```

```bash
gh pr create --base staging --title "chore: versão 0.1.1+2" --body "$(cat <<'EOF'
## Summary
- Bump SemVer após mudanças já mergeadas na staging.
- Tag v0.1.1 (versionName). versionCode = 2.

## Test plan
- [ ] pubspec.yaml na versão nova
- [ ] Tag v0.1.1 no remoto
- [ ] CI verde (se disparar)

EOF
)"
```

Merge dessa PR na `staging`. A tag `v0.1.1` já existe no remoto; **ainda não** publique a GitHub Release (falta o APK e o merge na `main`).

### 7. Abrir PR `staging` → `main`

Só depois do bump mergeado na `staging`:

```bash
git fetch origin

gh pr create --base main --head staging --title "release: v0.1.1" --body "$(cat <<'EOF'
## Summary
- Promove staging → main com a versão já bumpada
- Inclui as features/fixes do ciclo + commit `chore: versão …`

## Test plan
- [ ] Origem da PR é staging (não uma feat/fix)
- [ ] CI verde
- [ ] Após merge: build do APK release e GitHub Release v0.1.1

EOF
)"
```

Navegador: `https://github.com/pianolouvorja/apk/compare/main...staging`

### 8. Mergear → `main`

1. Merge só com origem **`staging`** e CI verde.
2. Atualize local:

```bash
git fetch origin
git switch main
git pull origin main
```

### 9. Build do APK release (você executa)

Na `main` atualizada, com working tree limpa:

```bash
git switch main
git pull origin main

# Tokens: exporte no shell, nunca commite e nunca os passe em chat.
# API_TOKEN: catálogo de hinos/Bíblia. GH_TOKEN: releases privadas do updater.
# Guarde os símbolos de obfuscação fora do Git para conseguir depurar crash reports.
mkdir -p build/symbols
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --dart-define=API_TOKEN="$API_TOKEN" \
  --dart-define=GH_TOKEN="$GH_TOKEN"
```

Saída:

```text
build/app/outputs/flutter-apk/app-release.apk
```

### Integridade do APK (obrigatório)

O `UpdateService` valida o campo `digest` SHA-256 do asset retornado pela API
do GitHub Releases antes de abrir o instalador. Depois do upload, confirme que
a API expõe o digest e compare com o artefato local:

```bash
sha256sum build/app/outputs/flutter-apk/app-release.apk
gh api repos/pianolouvorja/apk/releases/tags/v${VERSION} \
  --jq '.assets[] | select(.name | endswith(".apk")) | .digest'
```

Se a API ainda não retornar `sha256:<hash>`, o updater mantém TLS/GitHub como
origem confiável, mas a verificação explícita não é aplicada.

Opcional — nome amigável para a Release:

```bash
VERSION=0.1.1
cp build/app/outputs/flutter-apk/app-release.apk \
   "build/app/outputs/flutter-apk/louvorja-piano-${VERSION}.apk"
ls -lh build/app/outputs/flutter-apk/*.apk
```

Smoke no emulador/aparelho (opcional, recomendado):

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Confira na splash/configurações se a versão exibida é `v0.1.1`.

### 10. Publicar GitHub Release (notes + APK)

A tag já existe. Só publique **depois** da `main` ok e do APK gerado.

```bash
VERSION=0.1.1
APK="build/app/outputs/flutter-apk/louvorja-piano-${VERSION}.apk"
# se não renomeou:
# APK="build/app/outputs/flutter-apk/app-release.apk"

gh release create "v${VERSION}" \
  --title "v${VERSION}" \
  --notes "$(cat <<EOF
## LouvorJA PIANO Mobile v${VERSION}

### Destaques
- …

### Assets
- Android: APK release
EOF
)" \
  "$APK"
```

Notas geradas a partir dos commits/PRs:

```bash
gh release create "v${VERSION}" \
  --title "v${VERSION}" \
  --generate-notes \
  "$APK"
```

Se a tag já existir e a Release ainda não:

```bash
gh release create "v${VERSION}" --title "v${VERSION}" --generate-notes "$APK"
```

Se a Release já existir sem o APK:

```bash
gh release upload "v${VERSION}" "$APK" --clobber
```

Conferir:

```bash
gh release view "v${VERSION}"
```

#### Opção B — interface do GitHub

**Releases → Draft a new release** → tag `vX.Y.Z` → anexe o `.apk` → preencha notes → **Publish release**.

O `UpdateService` pega o **primeiro** asset cujo nome termina em `.apk`.

### 11. Atualizar branches locais (opcional)

```bash
git fetch origin
git switch main
git pull origin main
git switch staging
git pull origin staging
```

---

## Checklist rápido

- [ ] Branch de atuação a partir da `staging` atualizada
- [ ] Validado localmente (`flutter analyze` + `flutter test` + smoke)
- [ ] PR → `staging` (nunca feature direto na `main`)
- [ ] CI verde quando o workflow aplicar
- [ ] Versionamento em `chore/version-X.Y.Z` + PR → `staging` + tag `vX.Y.Z`
- [ ] `pubspec.yaml` com `X.Y.Z+N` (versionCode subiu)
- [ ] PR `staging` → `main` (origem obrigatoriamente `staging`)
- [ ] APK release gerado localmente (`flutter build apk --release`)
- [ ] GitHub Release publicada na tag **com notes + APK**
- [ ] (Opcional) Instalar o APK e conferir a versão na splash

## Problemas comuns

| Sintoma | Causa provável | O que fazer |
|---------|----------------|-------------|
| PR para `main` rejeitada | Origem ≠ `staging` | Só abra PR `staging` → `main` |
| Push direto em `staging`/`main` bloqueado | Branch protegida | Use PR |
| CI não roda na PR de `staging` | `ci.yml` só escuta `main` | Incluir `staging` no `on:` do workflow |
| APK não instala por cima do anterior | `versionCode` (`+N`) não subiu | Incremente o `+N` no `pubspec.yaml` |
| Banner de update não aparece | Release sem `.apk`, tag ≤ versão instalada, ou Release não é `latest` | Conferir `gh release view` e o `versionName` do app |
| Hinos/Bíblia falham no APK | Build sem `API_TOKEN` | Rebuild com `--dart-define=API_TOKEN=...` |
| `flutter: command not found` | PATH sem o SDK | `export PATH="/home/Arquivos/AmbienteDev/SDKs/flutter/bin:$PATH"` |
| Gradle pede keystore / cast null | `key.properties` ausente em config antiga | Release cai na chave debug; para loja, crie keystore + `key.properties` (não commitar) |
| `gh pr create` → must be a collaborator | Conta `gh` sem permissão | `gh auth switch` ou abrir PR no navegador |

## Arquivos relacionados

- `pubspec.yaml` — **única** fonte de versão (`version: X.Y.Z+N`)
- `lib/core/constants/app_version.dart` — lê a versão em runtime
- `lib/core/services/update_service.dart` — GitHub Releases `pianolouvorja/apk`
- `android/app/build.gradle.kts` — `versionName` / `versionCode` via Flutter
- `.github/workflows/ci.yml` — analyze, test, build debug
- `android/.gitignore` — `key.properties` e keystores
- `.gitignore` — `docs/` (este arquivo não vai para o remoto)
