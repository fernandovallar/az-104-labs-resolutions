#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/load_env.sh"

if [[ "${REUSE_SHARED:-0}" != "1" ]]; then
  echo "REUSE_SHARED=0 -> skipping shared bootstrap" && exit 0
fi

az group create -n "$SHARED_RG" -l "$AZURE_LOCATION" --tags "shared=yes" "owner=${PREFIX:-az104}" 1>/dev/null

# Example: shared Log Analytics
az monitor log-analytics workspace create -g "$SHARED_RG" -n "${PREFIX}-laws" -l "$AZURE_LOCATION" >/dev/null

echo "Shared baseline ready in RG: $SHARED_RG"
