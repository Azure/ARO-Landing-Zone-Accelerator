param principalId string
param resourceGroupId string
param contributorRoleId string
param userAccessAdminRoleId string

resource assignContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, resourceGroupId, contributorRoleId)
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalType: 'ServicePrincipal'
  }
}

resource assignUserAccessAdminRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, resourceGroupId, userAccessAdminRoleId)
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', userAccessAdminRoleId)
    principalType: 'ServicePrincipal'
  }
}
