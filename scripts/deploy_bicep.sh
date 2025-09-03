#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/load_env.sh"

CMD="${1:?validate|whatif|deploy}"
LAB_NUM="${2:?LAB number (e.g., 04)}"

RG="$(./scripts/ensure_rg.sh "$LAB_NUM")"
LAB_DIR="labs/lab${LAB_NUM}"
FILE="$LAB_DIR/main.bicep"
PARAMS="$LAB_DIR/lab.parameters.json"

[[ -f "$FILE" ]] || { echo "Bicep not found: $FILE"; exit 1; }
[[ -f "$PARAMS" ]] || PARAMS=""

COMMON_PARAMS=(
  prefix=${PREFIX:-az104}
  location=$AZURE_LOCATION
  reuseShared=${REUSE_SHARED:-0}
  sharedRg=${SHARED_RG:-""}
)

case "$CMD" in
  validate)
    az deployment group validate -g "$RG" -f "$FILE" ${PARAMS:+-p "$PARAMS"} -p "${COMMON_PARAMS[@]}"
    ;;
  whatif)
    az deployment group what-if -g "$RG" -f "$FILE" ${PARAMS:+-p "$PARAMS"} -p "${COMMON_PARAMS[@]}"
    ;;
  deploy)
    az deployment group create -g "$RG" -f "$FILE" ${PARAMS:+-p "$PARAMS"} -p "${COMMON_PARAMS[@]}"
    ;;
  *)
    echo "unknown command: $CMD" && exit 1
    ;;
esac
