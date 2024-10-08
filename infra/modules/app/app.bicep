param location string = resourceGroup().location
param tags object = {}
param appServiceName string
param appServicePlanName string
param stagingSlotEnabled bool = false
param sharedResourceGroupName string
param keyVaultName string
param apimServiceName string = ''
param logAnalyticsWorkspaceId string = ''
param appInsightsConnectionString string = ''
param appInsightsInstrumentationKey string = ''

param azureOpenaiEndpoint string
param azureOpenaiApiVersion string
param azureOpenaiApiModel string
param azureOpenaiApiModelEmbedding string
param azureSearchEndpoint string
param azureSearchApiVersion string
param azureSearchIndexName string
param azureCosmosEndpoint string
param azureCosmosDatabase string
param azureCosmosContainer string

@secure()
param azureOpenaiApiKey string
@secure()
param azureSearchApiKey string
@secure()
param azureSearchAdminKey string
@secure()
param storageConnectionString string
@secure()
param azureCosmosKey string

var appSettings = {
  APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsConnectionString
  APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsInstrumentationKey
  APPINSIGHTS_PROFILERFEATURE_VERSION: '1.0.0'
  APPINSIGHTS_SNAPSHOTFEATURE_VERSION: '1.0.0'
  ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
  AZURE_OPENAI_ENDPOINT: azureOpenaiEndpoint
  AZURE_OPENAI_API_VERSION: azureOpenaiApiVersion
  AZURE_OPENAI_API_KEY: azureOpenaiApiKey
  AZURE_OPENAI_API_MODEL_CHAT: azureOpenaiApiModel
  AZURE_OPENAI_API_MODEL_EMBEDDING: azureOpenaiApiModelEmbedding
  AZURE_SEARCH_ENDPOINT: azureSearchEndpoint
  AZURE_SEARCH_API_VERSION: azureSearchApiVersion
  AZURE_SEARCH_API_KEY: azureSearchApiKey
  AZURE_SEARCH_ADMIN_KEY: azureSearchAdminKey
  AZURE_SEARCH_INDEX_NAME: azureSearchIndexName
  AZURE_STORAGE_CONNECTION_STRING: storageConnectionString
  AZURE_COSMOS_ENDPOINT: azureCosmosEndpoint
  AZURE_COSMOS_KEY: azureCosmosKey
  AZURE_COSMOS_DATABASE: azureCosmosDatabase
  AZURE_COSMOS_CONTAINER: azureCosmosContainer
}

// Standard role definition: Key Vault Secrets User
var keyVaultRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'

module appServicePlan './resources/appservice-plan.bicep' = {
  name: 'app-service-plan'
  params: {
    name: appServicePlanName
    location: location
    tags: tags
  }
}

module appService './resources/appservice.bicep' = {
  name: 'app-service'
  params: {
    name: appServiceName
    location: location
    tags: union(tags, { 'azd-service-name': 'app-core' })
    servicePlanId: appServicePlan.outputs.id
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    appSettings: appSettings
  }
  dependsOn: [
    appServicePlan
  ]
}

module appServiceStaging './resources/appservice-slot.bicep' = if (stagingSlotEnabled) {
  name: 'app-service-slot'
  params: {
    location: location
    tags: union(tags, { 'azd-service-name': 'app-core-staging' })
    appServiceName: appServiceName
    servicePlanId: appServicePlan.outputs.id
    appSettings: appSettings
  }
  dependsOn: [
    appServicePlan
  ]
}

module appServiceRoleAssignment '../keyvault/config/role-assignment.bicep' = {
  name: 'app-service-kv-role-assignment'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    principalId: appService.outputs.principalId
    roleDefinitionId: keyVaultRoleDefinitionId
    serviceId: appService.outputs.id
    keyVaultName: keyVaultName
  }
}

module appServiceApi '../apim/api/appservice-api.bicep' = if (apimServiceName != '') {
  name: 'app-service-api'
  params: {
    apimServiceName: apimServiceName
    backendUrl: appService.outputs.url
    backendResourceId: appService.outputs.id
  }
}
