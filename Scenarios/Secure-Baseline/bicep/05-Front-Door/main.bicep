targetScope = 'resourceGroup'

/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import {
  generateResourceName
  generateUniqueGlobalName
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

@description('The name of the Web Application Firewall (WAF) policy for the Front Door.')
param wafPolicyName string = generateUniqueGlobalName('webApplicationFirewall', workloadName, env, location, null, hash, [resourceGroup().id], 5, 24, false)

/* -------------------------- Private Link Service -------------------------- */

@description('The name of the Private Link Service.')
param privateLinkServiceName string = generateResourceName('privateLinkService', workloadName, env, location, null, hash)

@description('The resource of the internal load balancer of the ARO cluster.')
param internalLoadBalancerResourceId string

@description('The resource id of the subnet where the Private Link Service will be deployed, i.e. front door subnet.')
param frontDoorSubnetResourceId string

/* ------------------------------- Front Door ------------------------------- */

@description('The name of the Front Door profile.')
param frontDoorProfileName string = generateResourceName('frontDoor', workloadName, env, location, null, hash)

@description('The name of the endpoint.')
param endpointName string = 'endpoint-${substring(uniqueString(resourceGroup().id), 0, 6)}'

@description('The name of the origin group')
param originGroupName string = 'default-origin-group'

@description('The name of the origin')
param originName string = 'default-origin'

@description('The host name of the origin')
param originHostName string

/* -------------------------------------------------------------------------- */
/*                                   MODULES                                  */
/* -------------------------------------------------------------------------- */

/* ------------------------------- WAF Policy ------------------------------- */

module wafPolicy './modules/front-door/waf-policy.bicep' = {
  name: take('${deployment().name}-waf', 64) 
  params:{
    wafPolicyName: wafPolicyName
  }
}

/* -------------------------- Private Link Service -------------------------- */

module privateLinkService 'br/public:avm/res/network/private-link-service:0.2.0' = {
  name: take('${deployment().name}-pls', 64)
  params: {
    name: privateLinkServiceName
    location: location
    fqdns: []
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: internalLoadBalancerResourceId
      }
    ]
    ipConfigurations: [
      {
        name: '${privateLinkServiceName}_ipconfig_0'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: frontDoorSubnetResourceId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

/* ------------------------------- Front Door ------------------------------- */

module frontDoor './modules/front-door/front-door.bicep' = {
  name: take('${deployment().name}-afd', 64)
  params: {
    frontDoorProfileName: frontDoorProfileName
    privateLinkServiceId: privateLinkService.outputs.resourceId
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
output privateLinkServiceName string = privateLinkService.outputs.name

@description('The FQDN of the front door endpoint')
output frontDoorFQDN string = frontDoor.outputs.frontDoorFQDN
