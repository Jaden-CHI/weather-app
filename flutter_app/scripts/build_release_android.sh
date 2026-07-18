#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

DEFINES_FILE="${RELEASE_DEFINES_FILE:-release_defines.json}"

if [[ ! -f "$DEFINES_FILE" ]]; then
  echo "Missing $DEFINES_FILE"
  echo "Create it from release_defines.example.json and fill the release values."
  exit 1
fi

required_keys=(
  "API_BASE_URL"
)

json_value() {
  local key="$1"
  grep -E "\"$key\"[[:space:]]*:" "$DEFINES_FILE" \
    | head -n 1 \
    | sed -E "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\1/"
}

for key in "${required_keys[@]}"; do
  if ! grep -Eq "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]+\"" "$DEFINES_FILE"; then
    echo "$DEFINES_FILE is missing a non-empty $key value."
    exit 1
  fi
done

flutter build appbundle \
  --release \
  --dart-define-from-file="$DEFINES_FILE" \
  "$@"

echo "Built AAB: build/app/outputs/bundle/release/app-release.aab"
