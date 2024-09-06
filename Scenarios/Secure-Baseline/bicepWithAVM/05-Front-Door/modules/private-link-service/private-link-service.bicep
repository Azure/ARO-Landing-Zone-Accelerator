@description('Name of the Private Link Service')
param privateLinkServiceName string

@description('Resource ID of the Load Balancer')
param loadBalancerId string

@description('Resource ID of the Virtual Network')
param subnetId string

@description('Location for the Private Link Service')
param location string

resource privateLinkService 'Microsoft.Network/privateLinkServices@2024-01-01' = {
  name: privateLinkServiceName
  location: location
  properties: {
    fqdns: []
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: loadBalancerId
      }
    ]
    ipConfigurations: [
      {
        name: '${privateLinkServiceName}_ipconfig_0'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

output privateLinkServiceId string = privateLinkService.id
