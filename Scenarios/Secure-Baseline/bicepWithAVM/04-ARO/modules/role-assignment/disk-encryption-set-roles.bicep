param principalId string
param aroResourceProviderPrincipalId string
param diskEncryptionSetName string
param readerRoleId string

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2022-07-02' existing = {
  name: diskEncryptionSetName
}

resource assignReaderRoleToSP 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, resourceGroup().id, readerRoleId, diskEncryptionSet.name)
  scope: diskEncryptionSet
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
    principalType: 'ServicePrincipal'
  }
}

resource assignReaderRoleToARORP 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aroResourceProviderPrincipalId, resourceGroup().id, readerRoleId, diskEncryptionSet.name)
  scope: diskEncryptionSet
  properties: {
    principalId: aroResourceProviderPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
    principalType: 'ServicePrincipal'
  }
}
