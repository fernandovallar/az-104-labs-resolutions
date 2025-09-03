#!/usr/bin/env bash
set -euo pipefail

# ===== config =====
TENANT_DOMAIN="${TENANT_DOMAIN:-fernandovallargmail.onmicrosoft.com}"
USER_ALIAS="az104-user1"
USER_UPN="${USER_ALIAS}@${TENANT_DOMAIN}"
USER_DISPLAY_NAME="az104-user1"
USER_JOB_TITLE="IT Lab Administrator"
USER_DEPARTMENT="IT"
USER_USAGE_LOCATION="US"

GROUP_NAME="IT Lab Administrators"
GROUP_DESC="Administrators that manage the IT lab"
GROUP_MAIL_NICKNAME="ITLabAdmins"

az account show >/dev/null 2>&1 || az login --only-show-errors >/dev/null

echo "==> Generating temporary password"
PASSWORD="$(openssl rand -base64 12)"
echo "Temporary password for ${USER_UPN}: ${PASSWORD}"

echo "==> Create or verify user"
if az ad user show --id "${USER_UPN}" --only-show-errors >/dev/null 2>&1; then
  echo "User already exists: ${USER_UPN}"
else
  az ad user create \
    --display-name "${USER_DISPLAY_NAME}" \
    --user-principal-name "${USER_UPN}" \
    --password "${PASSWORD}" \
    --force-change-password-next-sign-in true \
    --only-show-errors >/dev/null
  echo "User created."
fi

echo "==> Update user profile fields via Microsoft Graph (jobTitle, department, usageLocation)"
az rest --method PATCH \
  --url "https://graph.microsoft.com/v1.0/users/${USER_UPN}" \
  --headers "Content-Type=application/json" \
  --body "{\"jobTitle\":\"${USER_JOB_TITLE}\",\"department\":\"${USER_DEPARTMENT}\",\"usageLocation\":\"${USER_USAGE_LOCATION}\"}" \
  --only-show-errors >/dev/null

echo "==> Show user summary"
az rest --method GET \
  --url "https://graph.microsoft.com/v1.0/users/${USER_UPN}?\$select=id,userPrincipalName,displayName,jobTitle,department,usageLocation,accountEnabled" \
  --query "{id:id, userPrincipalName:userPrincipalName, displayName:displayName, jobTitle:jobTitle, department:department, usageLocation:usageLocation, accountEnabled:accountEnabled}" \
  -o jsonc

echo "==> Create or verify Security group"
# (Security is the default type for az ad group create)
GROUP_ID="$(az ad group list --filter "displayName eq '${GROUP_NAME}'" --query "[0].id" -o tsv)"
if [[ -z "${GROUP_ID}" ]]; then
  az ad group create \
    --display-name "${GROUP_NAME}" \
    --mail-nickname "${GROUP_MAIL_NICKNAME}" \
    --description "${GROUP_DESC}" \
    --only-show-errors >/dev/null
  GROUP_ID="$(az ad group list --filter "displayName eq '${GROUP_NAME}'" --query "[0].id" -o tsv)"
  echo "Group created: ${GROUP_NAME} (${GROUP_ID})"
else
  echo "Group already exists: ${GROUP_NAME} (${GROUP_ID})"
fi

echo "==> Add user to group"
USER_ID="$(az ad user show --id "${USER_UPN}" --query id -o tsv)"
IS_MEMBER="$(az ad group member check --group "${GROUP_ID}" --member-id "${USER_ID}" --query value -o tsv || echo false)"
if [[ "${IS_MEMBER}" == "true" ]]; then
  echo "User already a member."
else
  az ad group member add --group "${GROUP_ID}" --member-id "${USER_ID}" --only-show-errors
  echo "Added ${USER_UPN} to '${GROUP_NAME}'."
fi

echo "==> Done."
