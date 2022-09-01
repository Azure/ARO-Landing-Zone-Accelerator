param location string
param domain string
param rhps string
param clusterVnetName string
param masterVmSize string
param workerVmSize string
param podCidr string
param serviceCidr string
param clusterName string
param aadClientId string
param rpObjectId string
param aadObjectId string
param clusterRouteTable string

@secure()
param aadClientSecret string

@minValue(128)
param workerVmDiskSize int

@minValue(2)
param workerCount int

@description('Tags for resources')
param tags object = {
  env: 'Dev'
  dept: 'Ops'
}

@allowed([
  'Private'
  'Public'
])
param apiServerVisibility string

@description('Ingress Visibility')
@allowed([
  'Private'
  'Public'
])
param ingressVisibility string

var contribRole = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'

resource clusterVnetName_Microsoft_Authorization_id_name_aadObjectId 'Microsoft.Network/virtualNetworks/providers/roleAssignments@2018-09-01-preview' = {
  name: '${clusterVnetName}/Microsoft.Authorization/${guid(resourceGroup().id, deployment().name, aadObjectId)}'
  properties: {
    roleDefinitionId: contribRole
    principalId: aadObjectId
  }
}

resource clusterVnetName_Microsoft_Authorization_id_name_rpObjectId 'Microsoft.Network/virtualNetworks/providers/roleAssignments@2018-09-01-preview' = {
  name: '${clusterVnetName}/Microsoft.Authorization/${guid(resourceGroup().id, deployment().name, rpObjectId)}'
  properties: {
    roleDefinitionId: contribRole
    principalId: rpObjectId
  }
}

resource clusterRouteTable_Microsoft_Authorization_id_name_rpObjectId 'Microsoft.Network/routeTables/providers/roleAssignments@2018-09-01-preview' = {
  name: '${clusterRouteTable}/Microsoft.Authorization/${guid(resourceGroup().id, deployment().name, rpObjectId)}'
  properties: {
    roleDefinitionId: contribRole
    principalId: rpObjectId
  }
}
resource clusterName_resource 'Microsoft.RedHatOpenShift/OpenShiftClusters@2020-04-30' = {
  name: clusterName
  location: location
  tags: tags
  properties: {
    clusterProfile: {
      domain: domain
      resourceGroupId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/aro-${domain}-${location}'
      pullSecret: rhps
    }
    networkProfile: {
      podCidr: podCidr
      serviceCidr: serviceCidr
    }
    servicePrincipalProfile: {
      clientId: aadClientId
      clientSecret: aadClientSecret
    }
    masterProfile: {
      vmSize: masterVmSize
      subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', clusterVnetName, 'master-aro')
    }
    workerProfiles: [
      {
        name: 'worker'
        vmSize: workerVmSize
        diskSizeGB: workerVmDiskSize
        subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', clusterVnetName, 'worker-aro')
        count: workerCount
      }
    ]
    apiserverProfile: {
      visibility: apiServerVisibility
    }
    ingressProfiles: [
      {
        name: 'default'
        visibility: ingressVisibility
      }
    ]
  }
}
