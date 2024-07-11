using 'main.bicep'

param hubVirtualNetworkId =  '<hubVirtualNetworkId>'

param logAnalyticsWorkspaceId =  '<logAnalyticsWorkspaceId>'

param otherSubnetsConfig = {
  subnets: [
    /*
    {
      name: 'snet-custom-{workloadName}-{env}'
      addressPrefix: '10.1.6.0/24'
      // No optional properties specified
    }  
    */
  ]
}
