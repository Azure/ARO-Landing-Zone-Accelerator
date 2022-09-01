targetScope = 'subscription'

param VnetName string
param masterSubnetName string
param workerSubnetName string
param rtAROSubnetName string
param rgName string

resource subnetmaster 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rgName)
  name: '${VnetName}/${masterSubnetName}'
}

resource subnetworker 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rgName)
  name: '${VnetName}/${workerSubnetName}'
}
resource rtARO 'Microsoft.Network/routeTables@2021-02-01' existing ={
  scope: resourceGroup(rgName)
  name: rtAROSubnetName
}

module updateUDRmaster 'modules/vnet/subnet.bicep' = {
  scope: resourceGroup(rgName)
  name: 'updateUDRmaster'
  params: {
    subnetName: masterSubnetName
    vnetName: VnetName
    properties: {
      addressPrefix: subnetmaster.properties.addressPrefix
      routeTable: {
        id: rtARO.id
      }
    }
  }
}

module updateUDRworker 'modules/vnet/subnet.bicep' = {
  scope: resourceGroup(rgName)
  name: 'updateUDRworker'
  params: {
    subnetName: workerSubnetName
    vnetName: VnetName
    properties: {
      addressPrefix: subnetworker.properties.addressPrefix
      routeTable: {
        id: rtARO.id
      }
    }
  }
}
