# Define Variables
SUBSCRIPTION_ID="92bf2ce7-b898-4450-b627-dbff7d6fa18c"
RG=az104-rg2
SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}"
# Built-in policy definition (Require a tag and its value on resources)
POLICY_DEF="/providers/Microsoft.Authorization/policyDefinitions/1e30110a-5ceb-460c-a204-c1c3969c6d62"

# ------------------------------
# Task 1 - Create resource group
# ------------------------------

az group create --name $RG --location eastus --tags "Cost Center"=000

# ------------------------------
# Task 2 - Create policy assignment
# ------------------------------

az policy assignment create \
  --name require-cost-center-tag \
  --display-name "Require Cost Center tag and its value on resources" \
  --description "Require Cost Center tag and its value on all resources in the resource group" \
  --scope "$SCOPE" \
  --policy 1e30110a-5ceb-460c-a204-c1c3969c6d62 \
  --params '{
    "tagName":  { "value": "Cost Center" },
    "tagValue": { "value": "000" }
  }'

# Check if policy assignment was correct
az policy assignment list --scope "$SCOPE" -o table

# Check compliance in RG
az policy state summarize -g "$RG" -o jsonc

# list non-compliant resources
az policy state list -g "$RG" --query "[?complianceState=='NonCompliant'].[name,resourceType,policyAssignmentName]" -o table

# ------------------------------
# Task 3 – Inherit tag (Modify) + remediation + verify
# ------------------------------

SUBSCRIPTION_ID="92bf2ce7-b898-4450-b627-dbff7d6fa18c"
RG="az104-rg2"
SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}"

# Built-in policy: Inherit a tag from the resource group if missing (Modify)
INHERIT_DEF="/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"
ASSIGN_NAME="inherit-cost-center-from-rg"

echo "==> Ensure we are on the right subscription"
az account set --subscription "$SUBSCRIPTION_ID"

echo "==> Remove old 'Require' assignment if it exists"
az policy assignment delete --name require-cost-center-tag --scope "$SCOPE" --only-show-errors || true

echo "==> Ensure the RG has the tag Cost Center=000 (inherit pulls from RG)"
az group update -n "$RG" --set tags.'Cost Center'=000 >/dev/null

echo "==> Create 'inherit tag from RG if missing' WITH system-assigned identity (required for Modify) + grant it Contributor at the RG"
az policy assignment create \
  --name "$ASSIGN_NAME" \
  --display-name "Inherit the Cost Center tag and its value 000 from the RG if missing" \
  --description "Inherit Cost Center from resource group for missing tags" \
  --scope "$SCOPE" \
  --policy "ea3f2387-9b95-492a-a190-fcdc54f7b070" \
  --params '{ "tagName": { "value": "Cost Center" } }' \
  --mi-system-assigned \
  --identity-scope "$SCOPE" \
  --role "Contributor" \
  --only-show-errors \
  --location eastus

echo "==> (Optional) Create remediation task to fix existing resources"
az policy remediation create \
  --name "${ASSIGN_NAME}-remediate" \
  --resource-group "$RG" \
  --policy-assignment "$ASSIGN_NAME" \
  --resource-discovery-mode ReEvaluateCompliance \
  --only-show-errors || true

echo "==> Show current assignments at scope"
az policy assignment list --scope "$SCOPE" -o table

# -------- Verify by creating a tag-less storage account --------
echo "==> Create a Storage Account WITHOUT tags (Modify will add the tag)"
SA_NAME="az104sa199894943215675"; 
az storage account create \
  --name "$SA_NAME" \
  --resource-group "$RG" \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2 \
  --only-show-errors

echo "==> Storage account tags:"
az resource show -g "$RG" -n "$SA_NAME" --resource-type Microsoft.Storage/storageAccounts --query "tags" -o jsonc

echo "==> Policy compliance summary for the RG:"
az policy state summarize -g "$RG" -o jsonc
