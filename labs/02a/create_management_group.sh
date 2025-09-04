# 1) Create the MG
az account management-group create \
  --name az104-mg1 \
  --display-name az104-mg1

# 2) put your subscription under it
az account management-group subscription add \
  --name az104-mg1 \
  --subscription 92bf2ce7-b898-4450-b627-dbff7d6fa18c

# 3) ensure RBAC at that MG
MG_SCOPE="/providers/Microsoft.Management/managementGroups/az104-mg1"

# you as Owner (nice to have on the child MG too)
az role assignment create \
  --assignee-object-id 4a142662-a267-4976-a0d9-18558ab5e479 \
  --assignee-principal-type User \
  --role "Owner" \
  --scope "$MG_SCOPE"

# helpdesk as VM Contributor (lab 2nd Task)
az role assignment create \
  --assignee-object-id "7da35141-859c-4c9d-9d49-7a01ac923cb9" \
  --assignee-principal-type Group \
  --role "Virtual Machine Contributor" \
  --scope "$MG_SCOPE"
