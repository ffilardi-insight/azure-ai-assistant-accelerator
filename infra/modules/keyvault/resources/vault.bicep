param name string
param location string = resourceGroup().location
param tags object = {}
param logAnalyticsWorkspaceId string = ''
param skuFamily string = 'A'
param sku string = 'standard'
param publicNetworkAccess string = 'Enabled'
param networkAclsBypass string = 'AzureServices'
param networkAclsDefaultAction string = 'Allow'
param networkAclsVirtualNetworkRules array = []
param networkAclsIpRules array = []
param enableLogs bool = true
param enableAuditLogs bool = false
param enableMetrics bool = true

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': name })
  properties: {
    sku: {
      family: skuFamily
      name: sku
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enabledForTemplateDeployment: true
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      bypass: networkAclsBypass
      defaultAction: networkAclsDefaultAction
      virtualNetworkRules: networkAclsVirtualNetworkRules
      ipRules: networkAclsIpRules
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'Logging'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'audit'
        enabled: enableAuditLogs
      }
      {
        categoryGroup: 'allLogs'
        enabled: enableLogs
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: enableMetrics
      }
    ]
  }
}

output id string = keyVault.id
output name string = keyVault.name
output uri string = keyVault.properties.vaultUri
