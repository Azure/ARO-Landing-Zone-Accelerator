targetScope = 'resourceGroup'

/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import { visibilityType, encryptionAtHostType, masterNodesVmSizeType, workerProfileType } from './types.bicep'

import {
  getResourceName
} from '../commonModules/naming/functions.bicep'

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

@description('The name of the ARO cluster.')
@minLength(1)
@maxLength(30)
param aroClusterName string = getResourceName('aroCluster', workloadName, env, location, null, hash)

@description('The version of the ARO cluster (Optional).')
param aroClusterVersion string?

@description('The domain to use for the ARO cluster.')
param aroClusterDomain string = 'aroclusterdomain1234'

@description('The name of the managed resource group. Defaults to `aro-<domain>-<location>`.')
@minLength(1)
@maxLength(90)
param managedResourceGroupName string = 'aro-${aroClusterDomain}-${location}'

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
param masterNodesVmSize masterNodesVmSizeType = 'Standard_D8s_v5'

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

@description('The name of the spoke virtual network. This is required for role assignment for the ARO cluster.')
param spokeVirtualNetworkName string

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

@description('The name of the route table (Optional). If the name is not set the outbound type will be `loadbalancer`. This is required to configure UDR for the ARO cluster.')
param routeTableName string?

@description('The private IP address of the firewall (Optional). This is required to configure UDR for the ARO cluster. If not set, UDR is not configured and the outbound type of the ARO cluster is set to `Loadbalancer`. If set, the UDR is set for both the master nodes and worker nodes subnets, the outbound type of the ARO cluster is set to UserDefinedRouting, and the cluster API server and ingress need both to be private.')
param firewallPrivateIpAddress string?

/* -------------------------------- Security -------------------------------- */

@description('The resourceId of the security resource group (Optional). If set the disk encryption set will be used for the ARO cluster.')
param diskEncriptionSetResourceId string?

/* -------------------------------------------------------------------------- */
/*                                  VARIABLES                                 */
/* -------------------------------------------------------------------------- */

// The outbound type of the ARO cluster
var useUdr = !(empty(firewallPrivateIpAddress) || empty(routeTableName))
var outboundType = useUdr ? 'Loadbalancer' : 'UserDefinedRouting'

var managedResourceGRoupId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${managedResourceGroupName}'

var workerProfiles = [
  {
    name: workerProfile.name
    count: workerProfile.count
    vmSize: workerProfile.vmSize
    diskSizeGB: workerProfile.diskSizeGB
    encryptionAtHost: workerProfile.encryptionAtHost
    diskEncryptionSetId: workerProfile.?diskEncryptionSetId ?? diskEncriptionSetResourceId
    subnetId: workerProfile.?subnetId ?? workerNodesSubnetResourceId
  }
]

var useDiskEncryptionSet = !empty(diskEncriptionSetResourceId)

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
      diskEncryptionSetId: null
      vmSize: masterNodesVmSize
      subnetId: masterNodesSubnetResourceId
    }
    workerProfiles: workerProfiles
    servicePrincipalProfile: {
      clientId: servicePrincipalClientId
      clientSecret: servicePrincipalClientSecret
    }
  }
}

/* ---------------------------- Roles Assignment ---------------------------- */

module roleAssignments 'role-assignments.bicep' = {
  name: 'roleAssignments'
  params: {
    principalId: servicePrincipalObjectId
    aroResourceProviderPrincipalId: aroResourceProviderServicePrincipalObjectId
    resourceGroupId: resourceGroup().id
    vnetName: spokeVirtualNetworkName
    routeTableName: routeTableName
    diskEncryptionSetName: useDiskEncryptionSet ? last(split(diskEncriptionSetResourceId ?? '', '/')) : ''
  }
}
