#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/load_env.sh"

if ! az account show >/dev/null 2>&1; then
  az login --only-show-errors 1>/dev/null
fi

if [[ -n "${AZURE_SUBSCRIPTION_ID:-}" ]]; then
  az account set --subscription "$AZURE_SUBSCRIPTION_ID"
fi

az account show --query "{name:name, id:id, tenant:tenantId}" -o tsv
