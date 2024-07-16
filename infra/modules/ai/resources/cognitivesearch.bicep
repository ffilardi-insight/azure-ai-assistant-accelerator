param name string
param location string = resourceGroup().location
param tags object = {}
param sku string = 'basic'
param publicNetworkAccess string = 'Enabled'
param hostingMode string = 'default'
param semanticSearch string = 'free'
param partitionCount int = 1
param replicaCount int = 1
param ipRules array = []
param bypass string = 'AzureServices'
param keyVaultName string
param sharedResourceGroupName string
param logAnalyticsWorkspaceId string = ''
param enableLogs bool = true
param enableAuditLogs bool = false
param enableMetrics bool = true

var apiVersion = '2024-05-01-Preview'
var indexName = 'default-index'

var keyVaultSecretNameApiKey = 'cognitivesearch-api-key'
var keyVaultSecretNameAdminKey = 'cognitivesearch-admin-key'

resource searchService 'Microsoft.Search/searchServices@2024-03-01-Preview' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': name })
  sku: {
    name: sku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    partitionCount: partitionCount
    replicaCount: replicaCount
    hostingMode: hostingMode
    networkRuleSet: {
      ipRules: ipRules
      bypass: bypass
    }
    semanticSearch: semanticSearch
    publicNetworkAccess: publicNetworkAccess
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'Logging'
  scope: searchService
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
        {
          category: null
          categoryGroup: 'allLogs'
          enabled: enableLogs
      }
      {
          category: null
          categoryGroup: 'audit'
          enabled: enableAuditLogs
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

module keyVaultSecretApiKey '../../keyvault/config/secret.bicep' = {
  name: 'aisearch-secret-api-key'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    secretName: keyVaultSecretNameApiKey
    secretValue: searchService.listQueryKeys().value[0].key
  }
}

module keyVaultSecretAdminKey '../../keyvault/config/secret.bicep' = {
  name: 'aisearch-secret-admin-key'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    secretName: keyVaultSecretNameAdminKey
    secretValue: searchService.listAdminKeys().primaryKey
  }
}

output id string = searchService.id
output name string = searchService.name
output uri string = 'https://${searchService.name}.search.windows.net/'
output secretReferenceApiKey string = keyVaultSecretApiKey.outputs.secretReference
output secretReferenceAdminKey string = keyVaultSecretAdminKey.outputs.secretReference
output apiVersion string = apiVersion
output indexName string = indexName
