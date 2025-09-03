#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/load_env.sh"

LAB_NUM="${1:?LAB number required (e.g., 04)}"
RG="${LAB_RG_PREFIX}-${LAB_NUM}"

az group create -n "$RG" -l "$AZURE_LOCATION" --tags "lab=${LAB_NUM}" "owner=${PREFIX:-az104}" 1>/dev/null
echo "$RG"
