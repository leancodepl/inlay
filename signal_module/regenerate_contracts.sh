#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SIGNAL_MODULE_DIR="${REPO_ROOT}/signal_module"
GENERATOR_DIR="${REPO_ROOT}/leancode_add2app_gen"
SCHEMA_PATH="${SIGNAL_MODULE_DIR}/pigeons/schema.dart"

if [[ ! -f "${SCHEMA_PATH}" ]]; then
  echo "Schema not found: ${SCHEMA_PATH}" >&2
  exit 1
fi

if [[ ! -d "${GENERATOR_DIR}" ]]; then
  echo "Generator package not found: ${GENERATOR_DIR}" >&2
  exit 1
fi

echo "==> Generating Pigeon contracts"
(
  cd "${SIGNAL_MODULE_DIR}"
  dart run pigeon --input pigeons/schema.dart
)

echo "==> Generating add2app contracts"
(
  cd "${GENERATOR_DIR}"
  dart run bin/leancode_add2app_gen.dart \
    --input ../signal_module/pigeons/schema.dart \
    --dart-output ../signal_module/lib/src/navigator \
    --kotlin-output ../signal_module/android/src/main/kotlin/co/leancode/signal_module/navigator \
    --swift-output ../signal_module/ios/Classes
)

echo "==> Done"
