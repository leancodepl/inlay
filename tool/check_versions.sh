#!/usr/bin/env bash
# Asserts that all published-package versions match each other and the native
# artifact versions, and that inlay_compose's constraint on inlay is ^<version>.
# Optional $1: a git tag like v0.1.0 that must equal v<version>.
set -euo pipefail
cd "$(dirname "$0")/.."

pubspec_version() { grep -E '^version:' "$1/pubspec.yaml" | awk '{print $2}'; }

V=$(pubspec_version inlay)
err=0
check() { # name actual
  if [[ "$2" != "$V" ]]; then
    echo "MISMATCH: $1 is '$2', expected '$V'"
    err=1
  fi
}

check "inlay_compose pubspec" "$(pubspec_version inlay_compose)"
check "inlay_gen pubspec" "$(pubspec_version inlay_gen)"
check "inlay.podspec" "$(grep -E "s\.version" inlay/ios/inlay.podspec | sed -E "s/.*'([^']+)'.*/\1/")"
check "inlay android gradle" "$(grep -E '^version = ' inlay/android/build.gradle.kts | sed -E 's/.*"([^"]+)".*/\1/')"
check "inlay_compose android gradle" "$(grep -E '^version = ' inlay_compose/android/build.gradle.kts | sed -E 's/.*"([^"]+)".*/\1/')"

constraint=$(grep -E '^  inlay: ' inlay_compose/pubspec.yaml | awk '{print $2}')
if [[ "$constraint" != "^$V" ]]; then
  echo "MISMATCH: inlay_compose dep on inlay is '$constraint', expected '^$V'"
  err=1
fi

if [[ "${1:-}" != "" && "$1" != "v$V" ]]; then
  echo "MISMATCH: tag '$1' != 'v$V'"
  err=1
fi

if [[ $err -eq 0 ]]; then
  echo "All versions consistent: $V"
fi
exit $err
