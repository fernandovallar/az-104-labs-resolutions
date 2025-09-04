#!/usr/bin/env bash
set -euo pipefail

# ==== Config (override via env if you like) ====
MG_ID="${MG_ID:-az104-mg1}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-$(az account show --query id -o tsv 2>/dev/null || true)}"
ME_OBJECT_ID="${ME_OBJECT_ID:-4a142662-a267-4976-a0d9-18558ab5e479}"   # you
HELPDESK_GROUP_NAME="${HELPDESK_GROUP_NAME:-helpdesk}"                  # or set HELPDESK_GROUP_ID to skip lookup
HELPDESK_GROUP_ID="${HELPDESK_GROUP_ID:-"7da35141-859c-4c9d-9d49-7a01ac923cb9"}"
# ===============================================

# Colors
G="\033[32m"; Y="\033[33m"; R="\033[31m"; B="\033[36m"; N="\033[0m"
pass=0; fail=0

say()   { printf "${B}==>${N} %s\n" "$*"; }
ok()    { printf "${G}✔${N} %s\n" "$*"; pass=$((pass+1)); }
warn()  { printf "${Y}⚠${N} %s\n" "$*"; }
bad()   { printf "${R}✘${N} %s\n" "$*"; fail=$((fail+1)); }

need_az() {
  az account show >/dev/null 2>&1 || { warn "Not logged in – running 'az login'"; az login --only-show-errors >/dev/null; }
}

resolve_helpdesk() {
  if [[ -z "$HELPDESK_GROUP_ID" ]]; then
    HELPDESK_GROUP_ID="$(az ad group list --display-name "$HELPDESK_GROUP_NAME" --query "[0].id" -o tsv 2>/dev/null || true)"
    [[ -z "$HELPDESK_GROUP_ID" ]] && warn "Helpdesk group '$HELPDESK_GROUP_NAME' not found; skipping its RBAC checks."
  fi
}

# Start
need_az
TENANT_ID="$(az account show --query tenantId -o tsv)"
ROOT_MG_SCOPE="/providers/Microsoft.Management/managementGroups/${TENANT_ID}"
MG_SCOPE="/providers/Microsoft.Management/managementGroups/${MG_ID}"

say "Tenant: $TENANT_ID"
say "Subscription: ${SUBSCRIPTION_ID:-<none detected>}"
say "MG: $MG_ID"

# 1) MG exists & parent is root
if mg_json="$(az account management-group show --name "$MG_ID" --query "{name:name,displayName:displayName,tenantId:tenantId, parentId:details.parent.id}" -o json 2>/dev/null)"; then
  parent_id="$(echo "$mg_json" | jq -r '.parentId' 2>/dev/null || echo "")"
  [[ -z "$parent_id" ]] && parent_id="$(az account management-group show --name "$MG_ID" -o tsv --query details.parent.id 2>/dev/null || true)"
  printf "%s\n" "$mg_json" | sed 's/^/   /'
  if [[ "$parent_id" == "$ROOT_MG_SCOPE" ]]; then
    ok "Management Group '$MG_ID' exists and parent is the tenant root MG."
  else
    bad "MG '$MG_ID' exists but parent is unexpected: $parent_id"
  fi
else
  bad "Management Group '$MG_ID' not found."
fi

# 2) Subscription attached under MG (if we have a subscription id)
if [[ -n "${SUBSCRIPTION_ID:-}" ]]; then
  subs="$(az account management-group show --name "$MG_ID" --expand --query "children[?type=='/subscriptions'].name" -o tsv 2>/dev/null || true)"
  if echo "$subs" | grep -q -i "^${SUBSCRIPTION_ID}$"; then
    ok "Subscription $SUBSCRIPTION_ID is attached to $MG_ID."
  else
    bad "Subscription $SUBSCRIPTION_ID is NOT attached to $MG_ID."
    say "Attach with: az account management-group subscription add --name $MG_ID --subscription $SUBSCRIPTION_ID"
  fi
else
  warn "No subscription ID detected; skipping subscription check."
fi

# 3) RBAC checks at MG
say "Checking RBAC at MG scope: $MG_SCOPE"

# 3a) You are Owner
owner_count="$(az role assignment list --scope "$MG_SCOPE" --assignee-object-id "$ME_OBJECT_ID" \
  --query "[?roleDefinitionName=='Owner'] | length(@)" -o tsv 2>/dev/null || echo 0)"
if [[ "$owner_count" == "1" ]]; then
  ok "You ($ME_OBJECT_ID) have Owner at $MG_ID."
else
  bad "Missing Owner for you ($ME_OBJECT_ID) at $MG_ID."
  say "Grant with: az role assignment create --assignee-object-id $ME_OBJECT_ID --assignee-principal-type User --role 'Owner' --scope '$MG_SCOPE'"
fi

# 3b) Helpdesk group has VM Contributor
resolve_helpdesk
if [[ -n "$HELPDESK_GROUP_ID" ]]; then
  vmc_count="$(az role assignment list --scope "$MG_SCOPE" --assignee-object-id "$HELPDESK_GROUP_ID" \
    --query "[?roleDefinitionName=='Virtual Machine Contributor'] | length(@)" -o tsv 2>/dev/null || echo 0)"
  if [[ "$vmc_count" == "1" ]]; then
    ok "Helpdesk ($HELPDESK_GROUP_ID) has Virtual Machine Contributor at $MG_ID."
  else
    bad "Helpdesk ($HELPDESK_GROUP_ID) missing Virtual Machine Contributor at $MG_ID."
    say "Grant with: az role assignment create --assignee-object-id $HELPDESK_GROUP_ID --assignee-principal-type Group --role 'Virtual Machine Contributor' --scope '$MG_SCOPE'"
  fi
else
  warn "Skipped Helpdesk RBAC check (group not found)."
fi

# 4) Pretty tables
say "Summary tables:"
az account management-group show --name "$MG_ID" --expand --output table || true
echo
az role assignment list --scope "$MG_SCOPE" \
  --query "[].{Role:roleDefinitionName, Assignee:principalName, Type:principalType}" -o table || true

# Exit code
echo
if [[ $fail -eq 0 ]]; then
  printf "${G}All checks passed (${pass} OK).${N}\n"
  exit 0
else
  printf "${R}%d check(s) failed, %d passed.${N}\n" "$fail" "$pass"
  exit 1
fi