@description('Name of the Web Application Firewall (WAF) policy')
param wafPolicyName string

resource wafPolicy 'Microsoft.Network/frontdoorwebapplicationfirewallpolicies@2024-02-01' = {
  name: wafPolicyName
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Detection'
      requestBodyCheck: 'Enabled'
      javascriptChallengeExpirationInMinutes: 30
    }
    customRules: {
      rules: []
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
          ruleSetAction: 'Block'
          ruleGroupOverrides: []
          exclusions: []
        }
      ]
    }
  }
}

@description('The resource ID of the created WAF policy')
output wafPolicyId string = wafPolicy.id
