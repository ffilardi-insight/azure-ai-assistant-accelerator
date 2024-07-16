param name string
param location string = resourceGroup().location
param tags object = {}
param sku string = 'S0'
param chatModelDeploymentName string = 'chat'
param chatModelName string = 'gpt-35-turbo'
param chatModelVersion string = '0613'
param chatModelSku string = 'Standard'
param chatModelCapacity int = 300
param chatRaiPolicyName string = 'Microsoft.DefaultV2'
param embeddingModelDeploymentName string = 'embedding'
param embeddingModelName string = 'text-embedding-ada-002'
param embeddingModelVersion string = '2'
param embeddingModelSku string = 'Standard'
param embeddingModelCapacity int = 100
param embeddingRaiPolicyName string = 'Microsoft.DefaultV2'
param customSubDomainName string = name
param kind string = 'OpenAI'
param publicNetworkAccess string = 'Enabled'
param networkDefaultAction string = 'Allow'
param logAnalyticsWorkspaceId string = ''
param enableLogs bool = true
param enableAuditLogs bool = false
param enableMetrics bool = true
param keyVaultName string
param sharedResourceGroupName string

var apiVersion = '2024-02-15-preview'
var keyVaultSecretName = 'openai-api-key'

var deployments = [
  {
    name: chatModelDeploymentName
    model: {
      format: kind
      name: chatModelName
      version: chatModelVersion
    }
    sku: {
      name: chatModelSku
      capacity: chatModelCapacity
    }
    raiPolicyName: chatRaiPolicyName
  }
  {
    name: embeddingModelDeploymentName
    model: {
      format: kind
      name: embeddingModelName
      version: embeddingModelVersion
    }
    sku: {
      name: embeddingModelSku
      capacity: embeddingModelCapacity
    }
    raiPolicyName: embeddingRaiPolicyName
  }
]

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': name })
  kind: kind
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: networkDefaultAction
    }
  }
  sku: {
    name: sku
  }
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in deployments: {
  parent: account
  name: deployment.name
  sku: deployment.sku
  properties: {
    model: deployment.model
    scaleSettings: deployment.?scaleSettings ?? null
    raiPolicyName: deployment.?raiPolicyName ?? null
  }
}]

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
  name: 'openai-secret'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    secretName: keyVaultSecretName
    secretValue: account.listKeys().key1
  }
}

output id string = account.id
output name string = account.name
output uri string = account.properties.endpoint
output secretReference string = keyVaultSecret.outputs.secretReference
output secretName string = keyVaultSecretName
output apiVersion string = apiVersion
output chatModel string = chatModelDeploymentName
output embeddingModel string = embeddingModelDeploymentName
