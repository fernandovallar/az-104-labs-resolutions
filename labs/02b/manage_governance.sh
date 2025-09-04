# Define Variables
SUBSCRIPTION_ID="92bf2ce7-b898-4450-b627-dbff7d6fa18c"
RG=az104-rg2
SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}"
# Built-in policy definition (Require a tag and its value on resources)
POLICY_DEF="/providers/Microsoft.Authorization/policyDefinitions/1e30110a-5ceb-460c-a204-c1c3969c6d62"

# Task 1 - Create resource group
az group create --name $RG --location eastus --tags "Cost Center"=000

# Task 2 - Create policy assignment
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