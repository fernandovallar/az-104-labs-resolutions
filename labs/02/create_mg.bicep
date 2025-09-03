targetScope = 'tenant'

var mgId            = 'az104-mg1'
var mgDisplayName   = 'az104-mg1'

// create the management group
resource mg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: mgId
  properties: { displayName: mgDisplayName }
}
