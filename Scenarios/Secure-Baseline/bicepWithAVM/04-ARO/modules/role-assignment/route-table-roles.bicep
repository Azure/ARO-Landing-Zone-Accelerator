param principalId string
param aroResourceProviderPrincipalId string
param routeTableName string
param contributorRoleId string

resource routeTable 'Microsoft.Network/routeTables@2023-09-01' existing = {
  name: routeTableName
}

resource assignContributorRoleToSP 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, resourceGroup().id, contributorRoleId, routeTable.name)
  scope: routeTable
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource assignContributorRoleToARORP 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aroResourceProviderPrincipalId, resourceGroup().id, contributorRoleId, routeTable.name)
  scope: routeTable
  properties: {
    principalId: aroResourceProviderPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalType: 'ServicePrincipal'
  }
}
