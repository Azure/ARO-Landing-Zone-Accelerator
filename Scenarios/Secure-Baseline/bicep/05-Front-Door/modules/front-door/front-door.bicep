/* -------------------------------------------------------------------------- */
/*                                 PARAMETERES                                */
/* -------------------------------------------------------------------------- */

@description('Name of the Azure Front Door profile')
param frontDoorProfileName string

@description('External ID of the Private Link Service')
param privateLinkServiceId string

@description('External ID of the Web Application Firewall policy')
param wafPolicyId string

@description('Name of the endpoint')
param endpointName string

@description('Name of the origin group')
param originGroupName string

@description('Name of the origin')
param originName string

@description('Hostname of the origin')
param originHostName string

@description('Location of the Private Link')
param privateLinkLocation string

@description('The tags to apply to the resources. Defaults to an object with the environment and workload name.')
param tags object

/* -------------------------------------------------------------------------- */
/*                                  RESOURCES                                 */
/* -------------------------------------------------------------------------- */

resource frontDoorProfile 'Microsoft.Cdn/profiles@2024-05-01-preview' = {
  name: frontDoorProfileName
  location: 'Global'
  tags: tags
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    originResponseTimeoutSeconds: 60
  }
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdendpoints@2024-05-01-preview' = {
  parent: frontDoorProfile
  name: endpointName
  location: 'Global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource originGroup 'Microsoft.Cdn/profiles/origingroups@2024-05-01-preview' = {
  parent: frontDoorProfile
  name: originGroupName
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'GET'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

resource origin 'Microsoft.Cdn/profiles/origingroups/origins@2024-05-01-preview' = {
  parent: originGroup
  name: originName
  properties: {
    hostName: originHostName
    httpPort: 80
    httpsPort: 443
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    sharedPrivateLinkResource: {
      privateLink: {
        id: privateLinkServiceId
      }
      privateLinkLocation: privateLinkLocation
      requestMessage: 'Private link service from AFD'
    }
    enforceCertificateNameCheck: true
  }
}

resource securityPolicy 'Microsoft.Cdn/profiles/securitypolicies@2024-05-01-preview' = {
  parent: frontDoorProfile
  name: 'wafpolicy-${uniqueString(frontDoorProfileName)}'
  properties: {
    parameters: {
      wafPolicy: {
        id: wafPolicyId
      }
      associations: [
        {
          domains: [
            {
              id: frontDoorEndpoint.id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
      type: 'WebApplicationFirewall'
    }
  }
  dependsOn:[
    origin
  ]
}

resource route 'Microsoft.Cdn/profiles/afdendpoints/routes@2024-05-01-preview' = {
  parent: frontDoorEndpoint
  name: 'default-route'
  properties: {
    customDomains: []
    grpcState: 'Disabled'
    originGroup: {
      id: originGroup.id
    }
    ruleSets: []
    supportedProtocols: [
      'Http'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Disabled'
    enabledState: 'Enabled'
  }
  dependsOn:[
    origin
    securityPolicy
  ]
}

/* -------------------------------------------------------------------------- */
/*                                   OUTPUTS                                  */
/* -------------------------------------------------------------------------- */ 

output frontDoorFQDN string = frontDoorEndpoint.properties.hostName
