#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/load_env.sh"
LAB_NUM="${1:?LAB number required (e.g., 04)}"
RG="${LAB_RG_PREFIX}-${LAB_NUM}"

echo "Deleting RG: $RG"
az group delete -n "$RG" --yes --no-wait
