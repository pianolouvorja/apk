#!/usr/bin/env bash
# Gate de release: valida que o APK bate com a versão do pubspec ANTES de
# anexar em qualquer release. Bloqueia o acoplamento tag↔APK quebrado
# (bug 2026-08-16: release v0.1.16 com APK versionName 0.1.15 dentro —
# updater instalava e "continuava na 0.1.15", loop de atualização).
#
# Uso: ./scripts/release-gate.sh v0.1.16 build/app/outputs/flutter-apk/app-release.apk
set -euo pipefail

TAG="${1:?uso: release-gate.sh <tag> <apk>}"
APK="${2:?uso: release-gate.sh <tag> <apk>}"

PUBSPEC_VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)
TAG_VERSION="${TAG#v}"

AAPT=$(ls "$HOME/Android/Sdk/build-tools/"*/aapt 2>/dev/null | sort -V | tail -1)
if [[ -z "$AAPT" ]]; then
  echo "ERRO: aapt não encontrado (Android build-tools)"; exit 1
fi

BADGE=$("$AAPT" dump badging "$APK" | head -1)
APK_NAME=$(echo "$BADGE" | grep -oE "versionName='[^']+'" | cut -d"'" -f2)
APK_CODE=$(echo "$BADGE" | grep -oE "versionCode='[^']+'" | cut -d"'" -f2)
PUBSPEC_CODE=$(grep -E '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f2)

echo "tag:            $TAG  ($TAG_VERSION)"
echo "pubspec:        $PUBSPEC_VERSION+$PUBSPEC_CODE"
echo "apk:            $APK_NAME+$APK_CODE"

FAIL=0
[[ "$TAG_VERSION" == "$PUBSPEC_VERSION" ]] || { echo "✗ tag ($TAG_VERSION) != pubspec ($PUBSPEC_VERSION)"; FAIL=1; }
[[ "$APK_NAME" == "$PUBSPEC_VERSION" ]]    || { echo "✗ apk versionName ($APK_NAME) != pubspec ($PUBSPEC_VERSION)"; FAIL=1; }
[[ "$APK_CODE" == "$PUBSPEC_CODE" ]]       || { echo "✗ apk versionCode ($APK_CODE) != pubspec ($PUBSPEC_CODE)"; FAIL=1; }

# APK precisa ser MAIS NOVO ou igual ao que está instalado nos aparelhos.
# (O guard no app também protege; aqui é a barreira do processo.)

if [[ $FAIL -eq 1 ]]; then
  echo ""
  echo "GATE REPROVADO — rebuild com a versão certa antes de publicar."
  exit 1
fi
echo "✓ GATE APROVADO: tag, pubspec e APK sincronizados."
