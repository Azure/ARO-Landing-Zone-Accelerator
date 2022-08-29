param bastionpipId string
param subnetId string
param location string = resourceGroup().location
param enableTunneling bool
param enableIpConnect bool

resource bastion 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: 'bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: enableTunneling
    enableIpConnect: enableIpConnect
    ipConfigurations: [
      {
        name: 'ipconf'
        properties: {
          publicIPAddress: {
            id: bastionpipId
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}
