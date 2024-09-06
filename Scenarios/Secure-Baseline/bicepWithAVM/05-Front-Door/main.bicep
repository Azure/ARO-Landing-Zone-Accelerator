targetScope = 'resourceGroup'

/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import {
  generateResourceName
  generateUniqueGlobalName
  generateResourceNameFromParentResourceName
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

/* ------------------------------- WAF Policy ------------------------------- */

@description('Name of the Front Door Web Application Firewall (WAF) policy')
param wafPolicyName string = generateUniqueGlobalName('webApplicationFirewall', workloadName, env, location, null, hash, [resourceGroup().id], 5, 24, false)

/* -------------------------- Private Link Service -------------------------- */

@description('Name of the Private Link Service')
param privateLinkServiceName string = generateResourceName('privateLinkService', workloadName, env, location, null, hash)

@description('Resource ID of the internal Load Balancer')
param internalLoadBalancerResourceId string

@description('Resource ID of the Worker Subnet')
param workerNodesSubnetResourceId string

/* ------------------------------- Front Door ------------------------------- */

@description('Name of the Azure Front Door profile')
param frontDoorProfileName string = generateResourceName('frontDoor', workloadName, env, location, null, hash)

@description('Name of the endpoint')
param endpointName string = 'hello-world-endpoint'

@description('Name of the origin group')
param originGroupName string = 'default-origin-group'

@description('Name of the origin')
param originName string = 'default-origin'

@description('Hostname of the origin')
param originHostName string

/* -------------------------------------------------------------------------- */
/*                                   MODULES                                  */
/* -------------------------------------------------------------------------- */

module wafPolicy './modules/front-door/waf-policy.bicep' = {
  name: 'wafPolicyDeployment'
  params: {
    wafPolicyName: wafPolicyName
  }
}

module privateLinkService './modules/private-link-service/private-link-service.bicep' = {
  name: 'privateLinkServiceDeployment'
  params: {
    privateLinkServiceName: privateLinkServiceName
    loadBalancerId: internalLoadBalancerResourceId
    subnetId: workerNodesSubnetResourceId
    location: location
  }
}

module frontDoor './modules/front-door/front-door.bicep' = {
  name: 'frontDoorDeployment'
  params: {
    frontDoorProfileName: frontDoorProfileName
    privateLinkServiceId: privateLinkService.outputs.privateLinkServiceId
    wafPolicyId: wafPolicy.outputs.wafPolicyId
    endpointName: endpointName
    originGroupName: originGroupName
    originName: originName
    originHostName: originHostName
    privateLinkLocation: location
    tags: tags
  }
  dependsOn: [
    wafPolicy
    privateLinkService
  ]
}

/* -------------------------------------------------------------------------- */
/*                                   OUTPUTS                                  */
/* -------------------------------------------------------------------------- */

@description('The private link service name.')
output privateLinkServiceName string = privateLinkService.outputs.privateLinkServiceName
