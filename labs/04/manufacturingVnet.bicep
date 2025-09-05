param vnetName string = 'ManufacturingVnet'
param location string = 'eastus'

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.30.0.0/16'
      ]
    }
    enableDdosProtection: false
  }
}

resource subnetShared 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: 'SharedServicesSubnet'
  parent: vnet
  properties: {
    addressPrefixes: [
      '10.30.20.0/24'
    ]
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource subnetDb 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: 'DatabaseSubnet'
  parent: vnet
  properties: {
    addressPrefixes: [
      '10.30.21.0/24'
    ]
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

output vnetId string = vnet.id
output sharedSubnetId string = subnetShared.id
output dbSubnetId string = subnetDb.id
