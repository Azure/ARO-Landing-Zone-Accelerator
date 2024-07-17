@description('The principal ID of the service principal.')
param principalId string

@description('The principal ID of the ARO resource provider service principal.')
param aroResourceProviderPrincipalId string

@description('The ID of the resource group.')
param resourceGroupId string

@description('The name of the virtual network.')
param vnetName string

@description('The name of the route table (optional).')
param routeTableName string = ''

@description('The name of the disk encryption set (optional).')
param diskEncryptionSetName string = ''

var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var userAccessAdminRoleId = '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

module resourceGroupRoles 'modules/role-assignment/resource-group-roles.bicep' = {
  name: 'resourceGroupRoles'
  params: {
    principalId: principalId
    resourceGroupId: resourceGroupId
    contributorRoleId: contributorRoleId
    userAccessAdminRoleId: userAccessAdminRoleId
  }
}

module vnetRoles 'modules/role-assignment/vnet-roles.bicep' = {
  name: 'vnetRoles'
  params: {
    principalId: principalId
    aroResourceProviderPrincipalId: aroResourceProviderPrincipalId
    vnetName: vnetName
    contributorRoleId: contributorRoleId
  }
}

module routeTableRoles 'modules/role-assignment/route-table-roles.bicep' = if (!empty(routeTableName)) {
  name: 'routeTableRoles'
  params: {
    principalId: principalId
    aroResourceProviderPrincipalId: aroResourceProviderPrincipalId
    routeTableName: routeTableName
    contributorRoleId: contributorRoleId
  }
}

module diskEncryptionSetRoles 'modules/role-assignment/disk-encryption-set-roles.bicep' = if (!empty(diskEncryptionSetName)) {
  name: 'diskEncryptionSetRoles'
  params: {
    principalId: principalId
    aroResourceProviderPrincipalId: aroResourceProviderPrincipalId
    diskEncryptionSetName: diskEncryptionSetName
    readerRoleId: readerRoleId
  }
}
