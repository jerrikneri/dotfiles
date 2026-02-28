#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-workspace/context}"
OUT_FILE="${2:-workspace/context/_meta/learning-index.json}"
PROCESSED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

mkdir -p "$(dirname "$OUT_FILE")"

{
  printf '{\n  "version": 1,\n  "files": {\n'

  first=1
  for f in "$ROOT_DIR"/*/*.md; do
    [ -f "$f" ] || continue
    mtime_ms=$(( $(stat -f %m "$f") * 1000 ))

    if [ "$first" -eq 0 ]; then
      printf ',\n'
    fi
    first=0

    printf '    "%s": {\n' "$f"
    printf '      "mtimeMs": %s,\n' "$mtime_ms"
    printf '      "lastProcessedAt": "%s"\n' "$PROCESSED_AT"
    printf '    }'
  done

  printf '\n  }\n}\n'
} > "$OUT_FILE"

printf 'Updated %s\n' "$OUT_FILE"
