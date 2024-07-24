targetScope = 'resourceGroup'

/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import { visibilityType, encryptionAtHostType, workerProfileType } from './modules/aro/types.bicep'

import {
  generateResourceName
  generateResourceNameFromParentResourceName
  generateAroDomain
} from '../common-modules/naming/functions.bicep'

/* -------------------------------------------------------------------------- */
/*                                 PARAMETERS                                 */
/* -------------------------------------------------------------------------- */

@description('The name of the workload. Defaults to aro-lza.')
@minLength(3)
@maxLength(15)
param workloadName string = 'aro-lza'

@description('The location of the resources. Defaults to the deployment location.')
param location string = resourceGroup().location

@description('The type of environment. Defaults to DEV.')
@allowed([
  'DEV'
  'TST'
  'UAT'
  'PRD'
])
@minLength(3)
@maxLength(3)
param env string = 'DEV'

@minLength(3)
@maxLength(5)
@description('The hash to be added to every resource, configuration and exemption name. If not set, a unique string is generated for resources with global name based on its resource group id. The size of the hash is 5 characters.')
param hash string?

@description('The tags to apply to the resources. Defaults to an object with the environment and workload name.')
param tags object = hash == null ? {
  environment: env
  workload: workloadName
} : {
  environment: env
  workload: workloadName
  hash: hash
}

@description('Enable Azure Verified Modules (AVM) telemetry. Defaults to true.')
param enableAvmTelemetry bool = true

/* ------------------------------- ARO Cluster ------------------------------- */

@description('The name of the ARO cluster. Defaults to `<abbreviation-aro>-<workload-name>-<lower-case-env>-<location-short>[-<hash>]`.')
@minLength(1)
@maxLength(30)
param aroClusterName string = generateResourceName('aroCluster', workloadName, env, location, null, hash)

@description('The version of the ARO cluster (Optional).')
param aroClusterVersion string?

@description('The domain to use for the ARO cluster. Defaults to `<workload-name>-<lower-case-env>-<location-short>-<hash-or-unique-string>`.')
param aroClusterDomain string = generateAroDomain(workloadName, env, location, hash, [resourceGroup().id, aroClusterName], 5, 30)

@description('The name of the managed resource group. Defaults to `aro-<domain>-<location>`.')
@minLength(1)
@maxLength(90)
param managedResourceGroupName string = generateResourceName('resourceGroup', workloadName, env, location, 'managed-aro', hash)

@secure()
@description('The pull secret for the ARO cluster.')
param pullSecret string?

@description('The visibility of the API server. Defaults to `Private`.')
param apiServerVisibility visibilityType = 'Private'

@description('The visibility of the ingress. Defaults to `Private`.')
param ingressVisibility visibilityType = 'Private'

@description('Enable FIPS validated modules. Defaults to false.')
param enableFipsValidatedModules bool = false

@description('The VM size to use for the master nodes. Defaults to `Standard_D8s_v5`.')
param masterNodesVmSize string = 'Standard_D8s_v5'

@description('Enable encryption at host for the master nodes. Defaults to `Enabled`.')
param encryptionAtHostMasterNodes encryptionAtHostType = 'Enabled'

@description('The worker profile to use for the ARO cluster.')
param workerProfile workerProfileType = {
  name: 'worker'
  count: 3
  vmSize: 'Standard_D4s_v3'
  diskSizeGB: 128
  encryptionAtHost: 'Enabled'
}

/* ------------------------------- Networking ------------------------------- */

@description('The resource id of the spoke virtual network. This is required for role assignment for the ARO cluster.')
param spokeVirtualNetworkResourceId string

@description('The CIDR for the pods. Defaults to `10.128.0.0/14`')
param podCidr string = '10.128.0.0/14'

@description('The CIDR for the services. Defaults to `172.30.0.0/16`')
param serviceCidr string = '172.30.0.0/16'

@description('The resource id of the subnet to use for the master nodes.')
param masterNodesSubnetResourceId string

@description('The resource id of the subnet to use for the worker nodes.')
param workerNodesSubnetResourceId string

/* --------------------------- Service Principals --------------------------- */

@description('The client id of the service principal.')
param servicePrincipalClientId string

@description('The client secret of the service principal.')
@secure()
param servicePrincipalClientSecret string

@description('The object id of the service principal.')
param servicePrincipalObjectId string

@description('The object id of ARO resource provider service principal.')
param aroResourceProviderServicePrincipalObjectId string

/* --------------------------- User Defined Route --------------------------- */

@description('The resource id of the route table (Optional). If the name is not set the outbound type will be `loadbalancer`. This is required to configure UDR for the ARO cluster.')
param routeTableResourceId string?

@description('The private IP address of the firewall (Optional). This is required to configure UDR for the ARO cluster. If not set, UDR is not configured and the outbound type of the ARO cluster is set to `Loadbalancer`. If set, the UDR is set for both the master nodes and worker nodes subnets, the outbound type of the ARO cluster is set to UserDefinedRouting, and the cluster API server and ingress need both to be private.')
param firewallPrivateIpAddress string?

/* -------------------------------- Security -------------------------------- */

@description('The resourceId of the security resource group (Optional). If set the disk encryption set will be used for the ARO cluster.')
param diskEncryptionSetResourceId string?

/* -------------------------------------------------------------------------- */
/*                                  VARIABLES                                 */
/* -------------------------------------------------------------------------- */

/* ------------------------------- ARO Cluster ------------------------------ */

var managedResourceGRoupId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${managedResourceGroupName}'

var workerProfiles = [
  {
    name: workerProfile.name
    count: workerProfile.count
    vmSize: workerProfile.vmSize
    diskSizeGB: workerProfile.diskSizeGB
    encryptionAtHost: workerProfile.encryptionAtHost
    diskEncryptionSetId: workerProfile.?diskEncryptionSetId ?? diskEncryptionSetResourceId
    subnetId: workerProfile.?subnetId ?? workerNodesSubnetResourceId
  }
]

/* ---------------------------- Cluster Outbound ---------------------------- */

var useUdr = !(empty(firewallPrivateIpAddress) || empty(routeTableResourceId))
var outboundType = useUdr ? 'Loadbalancer' : 'UserDefinedRouting'

/* --------------------------- Disk Encryption Set -------------------------- */

var useDiskEncryptionSet = !empty(diskEncryptionSetResourceId)

/* ----------------------------- Built-in roles ----------------------------- */

// Azure built-in roles: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
// var contributorRoleResourceId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
// var userAccessAdministratorRoleResourceId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
var networkContributorRoleResourceId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
var readerRoleResourceId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

/* -------------------------------------------------------------------------- */
/*                                  RESOURCES                                 */
/* -------------------------------------------------------------------------- */

resource aroCluster 'Microsoft.RedHatOpenShift/openShiftClusters@2023-11-22' = {
  name: aroClusterName
  location: location
  tags: tags
  properties: {
    apiserverProfile: {
      visibility: apiServerVisibility
    }
    clusterProfile: {
      version: aroClusterVersion
      domain: aroClusterDomain
      #disable-next-line use-resource-id-functions
      resourceGroupId: managedResourceGRoupId
      pullSecret: pullSecret
      fipsValidatedModules: enableFipsValidatedModules ? 'Enabled' : 'Disabled'
    }
    ingressProfiles: [
      {
        name: 'default'
        visibility: ingressVisibility
      }
    ]
    networkProfile: {
      podCidr: podCidr
      serviceCidr: serviceCidr
      outboundType: outboundType ?? 'Loadbalancer'
    }
    masterProfile: {
      encryptionAtHost: encryptionAtHostMasterNodes
      diskEncryptionSetId: diskEncryptionSetResourceId
      vmSize: masterNodesVmSize
      subnetId: masterNodesSubnetResourceId
    }
    workerProfiles: workerProfiles
    servicePrincipalProfile: {
      clientId: servicePrincipalClientId
      clientSecret: servicePrincipalClientSecret
    }
  }
  dependsOn: [
    // assignContributorRoleToSPForApplicationResourceGroup
    // assignUserAccessAdministratorRoleToSPForApplicationResourceGroup
    assignNetworkContributorRoleToSPForVirtualNetwork
    assignNetworkContributorRoleToAROResourceProviderSPForVirtualNetwork
    assignNetworkContributorRoleToSPForRouteTable
    assignNetworkContributorRoleToAROResourceProviderSPForRouteTable
    assignReaderRoleToSPForDiskEncryptionSet
    assignReaderRoleToAROResourceProviderSPForDiskEncryptionSet
  ]
}

/* ----------------------------- Role Assignment ---------------------------- */

// resource assignContributorRoleToSPForApplicationResourceGroup 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(servicePrincipalObjectId, resourceGroup().id, contributorRoleResourceId)
//   scope: resourceGroup()
//   properties: {
//     principalId: servicePrincipalObjectId
//     roleDefinitionId: contributorRoleResourceId
//     principalType: 'ServicePrincipal'
//   }
// }

// resource assignUserAccessAdministratorRoleToSPForApplicationResourceGroup 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(servicePrincipalObjectId, resourceGroup().id, userAccessAdministratorRoleResourceId)
//   scope: resourceGroup()
//   properties: {
//     principalId: servicePrincipalObjectId
//     roleDefinitionId: userAccessAdministratorRoleResourceId
//     principalType: 'ServicePrincipal'
//   }
// }

// Spoke Virtual Network
module assignNetworkContributorRoleToSPForVirtualNetwork 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = if (useUdr) {
  name: take('${deployment().name}-sp-spoke-vnet-net-contributor', 64)
  params: {
    principalId: servicePrincipalObjectId
    resourceId: spokeVirtualNetworkResourceId
    roleDefinitionId: networkContributorRoleResourceId
    description: 'Assign Network Contributor role to the ARO Service Principal for the spoke virtual network.'
    principalType: 'ServicePrincipal'
    roleName: guid(servicePrincipalObjectId, resourceGroup().id, networkContributorRoleResourceId, spokeVirtualNetworkResourceId)
    enableTelemetry: enableAvmTelemetry
  }
}

module assignNetworkContributorRoleToAROResourceProviderSPForVirtualNetwork 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = if (useUdr) {
  name: take('${deployment().name}-aro-rp-spoke-vnet-net-contributor', 64)
  params: {
    principalId: aroResourceProviderServicePrincipalObjectId
    resourceId: spokeVirtualNetworkResourceId
    roleDefinitionId: networkContributorRoleResourceId
    description: 'Assign Network Contributor role to the ARO Resource Provider Service Principal for the spoke virtual network.'
    principalType: 'ServicePrincipal'
    roleName: guid(aroResourceProviderServicePrincipalObjectId, resourceGroup().id, networkContributorRoleResourceId, spokeVirtualNetworkResourceId)
    enableTelemetry: enableAvmTelemetry
  }
}

// Route Table
// If route table is deployed, both the RP SP and the SP needs to be contributor for the route table
module assignNetworkContributorRoleToSPForRouteTable 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = if (useUdr) {
  name: take('${deployment().name}-sp-rt-net-contributor', 64)
  params: {
    principalId: servicePrincipalObjectId
    resourceId: routeTableResourceId!
    roleDefinitionId: networkContributorRoleResourceId
    description: 'Assign Network Contributor role to the ARO Service Principal for the route table.'
    principalType: 'ServicePrincipal'
    roleName: guid(servicePrincipalObjectId, resourceGroup().id, networkContributorRoleResourceId, routeTableResourceId!)
    enableTelemetry: enableAvmTelemetry
  }
}

module assignNetworkContributorRoleToAROResourceProviderSPForRouteTable 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = if (useUdr) {
  name: take('${deployment().name}-aro-rp-rt-net-contributor', 64)
  params: {
    principalId: aroResourceProviderServicePrincipalObjectId
    resourceId: routeTableResourceId!
    roleDefinitionId: networkContributorRoleResourceId
    description: 'Assign Network Contributor role to the ARO Resource Provider Service Principal for the route table.'
    principalType: 'ServicePrincipal'
    roleName: guid(aroResourceProviderServicePrincipalObjectId, resourceGroup().id, networkContributorRoleResourceId, routeTableResourceId!)
    enableTelemetry: enableAvmTelemetry
  }
}

// Disk Encryption Set
// If disk encryption set is deployed, both the RP SP and the SP needs to be reader for the disk encryption set
module assignReaderRoleToSPForDiskEncryptionSet 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = if (useDiskEncryptionSet) {
  name: take('${deployment().name}-sp-des-reader', 64)
  params: {
    principalId: servicePrincipalObjectId
    resourceId: diskEncryptionSetResourceId!
    roleDefinitionId: readerRoleResourceId
    description: 'Assign Reader role to the ARO Service Principal for the disk encryption set.'
    principalType: 'ServicePrincipal'
    roleName: guid(servicePrincipalObjectId, resourceGroup().id, readerRoleResourceId, diskEncryptionSetResourceId!)
    enableTelemetry: enableAvmTelemetry
  }
}

module assignReaderRoleToAROResourceProviderSPForDiskEncryptionSet 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = if (useDiskEncryptionSet) {
  name: take('${deployment().name}-aro-rp-des-reader', 64)
  params: {
    principalId: aroResourceProviderServicePrincipalObjectId
    resourceId: diskEncryptionSetResourceId!
    roleDefinitionId: readerRoleResourceId
    description: 'Assign Reader role to the ARO Resource Provider Service Principal for the disk encryption set.'
    principalType: 'ServicePrincipal'
    roleName: guid(aroResourceProviderServicePrincipalObjectId, resourceGroup().id, readerRoleResourceId, diskEncryptionSetResourceId!)
    enableTelemetry: enableAvmTelemetry
  }
}
