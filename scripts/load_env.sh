#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &>/dev/null && pwd )"

if [[ -f "$ROOT_DIR/.env" ]]; then
  # shellcheck disable=SC2046
  export $(grep -vE '^(#|$)' "$ROOT_DIR/.env" | xargs -0 -I{} bash -c 'echo "{}"' 2>/dev/null || true)
else
  echo "WARN: .env not found; using defaults if any."
fi

: "${AZURE_LOCATION:=eastus}"
: "${LAB_RG_PREFIX:=${PREFIX:-az104}-lab}"