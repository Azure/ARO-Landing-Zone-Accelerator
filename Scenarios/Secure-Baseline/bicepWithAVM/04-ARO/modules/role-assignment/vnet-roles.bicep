param principalId string
param aroResourceProviderPrincipalId string
param vnetName string
param contributorRoleId string

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
}

resource assignContributorRoleToSP 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, resourceGroup().id, contributorRoleId, vnet.name)
  scope: vnet
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalType: 'ServicePrincipal'
  }
}

resource assignContributorRoleToARORP 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aroResourceProviderPrincipalId, resourceGroup().id, contributorRoleId, vnet.name)
  scope: vnet
  properties: {
    principalId: aroResourceProviderPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalType: 'ServicePrincipal'
  }
}
