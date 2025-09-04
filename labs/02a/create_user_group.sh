az ad group create \
  --display-name "helpdesk" \
  --mail-nickname "helpdesk" \
  --only-show-errors

# get its objectId (GUID)
HELPDESK_GROUP_ID=$(az ad group list --display-name "helpdesk" --query "[0].id" -o tsv)
echo "$HELPDESK_GROUP_ID"