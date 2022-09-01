param identityName string
param location string = resourceGroup().location

resource aroidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

output identityid string = aroidentity.id
output clientId string = aroidentity.properties.clientId
output principalId string = aroidentity.properties.principalId
