@export()
@description('A resource type.')
type resourceTypeType= 'resourceGroup' | 'virtualNetwork' | 'subnet' | 'networkSecurityGroup' | 'routeTable' | 'applicationGateway' | 'privateEndpoint' | 'networkInterface' | 'keyVault' | 'diskEncryptionSet' | 'keyVaultKey' | 'userManagedIdentity' | 'azureRedHatOpenShift' | 'virtualMachine' | 'firewall' | 'firewallPolicy' | 'firewallPolicyRuleGroup' | 'bastion' | 'publicIp' | 'logAnalyticsWorkspace' | 'containerRegistry' | 'virtualNetworkLink'

@export()
@description('Azure location type.')
type locationType = 'australiacentral' | 'australiacentral2' | 'australiaeast' | 'australiasoutheast' | 'brazilsouth' | 'brazilsoutheast' | 'canadacentral' | 'canadaeast' | 'centralindia' | 'centralus' | 'centraluseuap' | 'eastasia' | 'eastus' | 'eastus2' | 'francecentral' | 'francesouth' | 'germanynorth' | 'germanywestcentral' | 'israelcentral' | 'italynorth' | 'japaneast' | 'japanwest' | 'jioindiacentral' | 'jioindiawest' | 'koreacentral' | 'koreasouth' | 'northcentralus' | 'northeurope' | 'norwayeast' | 'norwaywest' | 'polandcentral' | 'qatarcentral' | 'southafricanorth' | 'southafricawest' | 'southcentralus' | 'southeastasia' | 'southindia' | 'swedencentral' | 'switzerlandnorth' | 'switzerlandwest' | 'uaecentral' | 'uaenorth' | 'uksouth' | 'ukwest' | 'westcentralus' | 'westeurope' | 'westindia' | 'westus' | 'westus2' | 'westus3'
