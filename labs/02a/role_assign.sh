#!/usr/bin/env bash
set -euo pipefail

TENANT_ID="9f0a2bdb-5c4d-48b7-8920-33282bcf8055"   # your tenantId == root MG id
ME_OBJECT_ID="4a142662-a267-4976-a0d9-18558ab5e479"  # your Entra user objectId
# -----------------------------------------------------------

ROOT_SCOPE="/providers/Microsoft.Management/managementGroups/${TENANT_ID}"
ROLES=("Owner" "User Access Administrator" "Management Group Contributor")

echo "==> Ensuring Azure CLI is logged in"
az account show >/dev/null 2>&1 || az login --only-show-errors >/dev/null

CUR_TENANT="$(az account show --query tenantId -o tsv)"
if [[ "$CUR_TENANT" != "$TENANT_ID" ]]; then
  echo "WARNING: current tenant ($CUR_TENANT) != expected tenant ($TENANT_ID)."
  echo "If this is wrong, re-login specifying the tenant:"
  echo "  az logout && az login --tenant $TENANT_ID"
fi

echo "==> Root MG scope: $ROOT_SCOPE"
echo "==> Your user objectId: $ME_OBJECT_ID"

assign_role() {
  local role="$1"
  echo "--> Ensuring role '$role' at root MG"
  if az role assignment list \
       --scope "$ROOT_SCOPE" \
       --assignee-object-id "$ME_OBJECT_ID" \
       --query "[?roleDefinitionName=='$role'] | length(@)" -o tsv | grep -q '^1$'; then
    echo "    already assigned."
  else
    # Try to create the assignment
    if ! az role assignment create \
         --assignee-object-id "$ME_OBJECT_ID" \
         --assignee-principal-type User \
         --role "$role" \
         --scope "$ROOT_SCOPE" --only-show-errors >/dev/null; then
      echo "    FAILED to assign '$role'."
      echo "    If you see AuthorizationFailed, flip this once in the portal:"
      echo "      Entra ID -> Properties -> 'Access management for Azure resources' = On"
      echo "    then re-run this script."
      exit 1
    fi
    echo "    assigned."
  fi
}

for r in "${ROLES[@]}"; do
  assign_role "$r"
done

echo "==> Verifying assignments:"
az role assignment list --scope "$ROOT_SCOPE" \
  --assignee-object-id "$ME_OBJECT_ID" \
  --query "[].{Role:roleDefinitionName,Scope:scope}" -o table

echo "✅ Done. You now have RBAC at the ROOT management group."
