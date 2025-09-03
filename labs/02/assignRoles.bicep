targetScope = 'managementGroup'

var meObjectId       = '4a142662-a267-4976-a0d9-18558ab5e479'   // My user
var helpdeskObjectId = '7da35141-859c-4c9d-9d49-7a01ac923cb9'   // helpdesk group

// Owner role
var ownerRoleGuid  = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
var ownerRoleDefId = tenantResourceId('Microsoft.Authorization/roleDefinitions', ownerRoleGuid)

// VM Contributor role
var vmContribGuid  = '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
var vmContribDefId = tenantResourceId('Microsoft.Authorization/roleDefinitions', vmContribGuid)

// you -> Owner at MG
resource ownerAtMg 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(meObjectId, ownerRoleGuid, 'owner-at-mg')
  properties: {
    roleDefinitionId: ownerRoleDefId
    principalId: meObjectId
    principalType: 'User'
  }
}

// helpdesk -> VM Contributor at MG
resource vmContributorAtMg 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(helpdeskObjectId, vmContribGuid, 'vm-contrib-at-mg')
  properties: {
    roleDefinitionId: vmContribDefId
    principalId: helpdeskObjectId
    principalType: 'Group'
  }
}
