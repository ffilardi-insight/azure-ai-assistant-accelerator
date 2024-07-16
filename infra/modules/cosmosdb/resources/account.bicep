param name string
param location string = resourceGroup().location
param tags object = {}
param sharedResourceGroupName string
param keyVaultName string
param databaseAccountOfferType string = 'Standard'
param failoverPriority int = 0
param isZoneRedundant bool = false
param defaultConsistencyLevel string = 'Session'
param maxIntervalInSeconds int = 5
param maxStalenessPrefix int = 100
param enableAutomaticFailover bool = false
param enableMultipleWriteLocations bool = false
param isVirtualNetworkFilterEnabled bool = false
param enableFreeTier bool = true
param enableAnalyticalStorage bool = false
param backupType string = 'Periodic'
param backupIntervalInMinutes int = 240
param backupRetentionIntervalInHours int = 8
param backupStorageRedundancy string = 'Local'
param virtualNetworkRules array = []
param networkAclBypass string = 'AzureServices'
param networkAclBypassResourceIds array = []
param ipRules array = []
param minimalTlsVersion string = 'Tls12'
param publicNetworkAccess string = 'Enabled'
param logAnalyticsWorkspaceId string = ''
param enableLogs bool = true
param enableAuditLogs bool = false
param enableMetrics bool = true

var keyVaultSecretName = 'cosmosdb-key'

var cosmosDbDatabase = 'assistant'
var cosmosDbContainer = 'chat_history'
var cosmosDbPartitionKey = '/session_id'

resource account 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': name })
  kind: 'GlobalDocumentDB'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    databaseAccountOfferType: databaseAccountOfferType
    locations: [
      {
        locationName: location
        failoverPriority: failoverPriority
        isZoneRedundant: isZoneRedundant
      }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: defaultConsistencyLevel
      maxIntervalInSeconds: maxIntervalInSeconds
      maxStalenessPrefix: maxStalenessPrefix
    }
    capabilities: []
    capacity: {
        totalThroughputLimit: 1000
    }
    virtualNetworkRules: virtualNetworkRules
    ipRules: ipRules
    networkAclBypass: networkAclBypass
    networkAclBypassResourceIds: networkAclBypassResourceIds
    minimalTlsVersion: minimalTlsVersion
    publicNetworkAccess: publicNetworkAccess
    enableMultipleWriteLocations: enableMultipleWriteLocations
    enableAutomaticFailover: enableAutomaticFailover
    isVirtualNetworkFilterEnabled: isVirtualNetworkFilterEnabled
    enableFreeTier: enableFreeTier
    enableAnalyticalStorage: enableAnalyticalStorage
    backupPolicy: {
      type: backupType
      periodicModeProperties: {
        backupIntervalInMinutes: backupIntervalInMinutes
        backupRetentionIntervalInHours: backupRetentionIntervalInHours
        backupStorageRedundancy: backupStorageRedundancy
      }
    }
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  name: cosmosDbDatabase
  parent: account
  properties: {
    resource: {
      id: cosmosDbDatabase
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  name: cosmosDbContainer
  parent: database
  properties: {
    resource: {
      id: cosmosDbContainer
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          cosmosDbPartitionKey
        ]
        kind: 'Hash'
        version: 2
      }
      uniqueKeyPolicy: {
        uniqueKeys: []
      }
      conflictResolutionPolicy: {
        mode: 'LastWriterWins'
        conflictResolutionPath: '/_ts'
      }
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'Logging'
  scope: account
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

module keyVaultSecret '../../keyvault/config/secret.bicep' = {
  name: 'cosmosdb-secret'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    secretName: keyVaultSecretName
    secretValue: account.listKeys().primaryMasterKey
  }
}

output id string = account.id
output name string = account.name
output uri string = account.properties.documentEndpoint
output secretReference string = keyVaultSecret.outputs.secretReference
output database string = cosmosDbDatabase
output container string = cosmosDbContainer
