targetScope = 'subscription'

@minLength(3)
@maxLength(10)
param environmentName string

@allowed(['westeurope', 'southcentralus', 'australiaeast', 'canadaeast', 'eastus', 'eastus2', 'francecentral', 'japaneast', 'northcentralus', 'swedencentral', 'switzerlandnorth', 'uksouth'])
param location string

// Resource Groups params
param monitorResourceGroupName string = ''
param sharedResourceGroupName string = ''
param appResourceGroupName string = ''
param aiResourceGroupName string = ''

// Logs & Monitoring Services params
param logAnalyticsName string = ''
param applicationInsightsName string = ''
param applicationInsightsDashboardName string = ''

// Shared Services params
param keyVaultName string = ''
param storageAccountName string = ''

// App Services params
param apimServiceName string = ''
param appServiceName string = ''
param appServicePlanName string = ''
param cosmosDbAccountName string = ''

// AI Services params
param openAiServiceName string = ''
param cognitiveSearchServiceName string = ''

// Set global variables
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Create Resource Groups

resource monitorResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(monitorResourceGroupName) ? monitorResourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}-monitor-${resourceToken}'
  location: location
  tags: tags
}

resource sharedResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(sharedResourceGroupName) ? sharedResourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}-shared-${resourceToken}'
  location: location
  tags: tags
}

resource appResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(appResourceGroupName) ? appResourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}-app-${resourceToken}'
  location: location
  tags: tags
}

resource aiResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(aiResourceGroupName) ? aiResourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}-ai-${resourceToken}'
  location: location
  tags: tags
}

// Deploy Logs & Monitoring Services

module monitor './modules/monitor/monitor.bicep' = {
  name: 'monitor'
  scope: monitorResourceGroup
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${environmentName}-${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${environmentName}-${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${environmentName}-${resourceToken}'
  }
}

// Deploy Shared Services

module keyVault './modules/keyvault/keyvault.bicep' = {
  name: 'keyvault'
  scope: sharedResourceGroup
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${environmentName}-${resourceToken}'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: monitor.outputs.logAnalyticsWorkspaceId
  }
}

module storageAccount './modules/storage/storage.bicep' = {
  name: 'storage'
  scope: sharedResourceGroup
  params: {
    name: !empty(storageAccountName) ? '${replace(storageAccountName,'-','')}' : '${abbrs.storageStorageAccounts}${replace(environmentName,'-','')}${resourceToken}'
    location: location
    tags: tags
    sharedResourceGroupName: sharedResourceGroup.name
    keyVaultName: keyVault.outputs.keyVaultName
    logAnalyticsWorkspaceId: monitor.outputs.logAnalyticsWorkspaceId
  }
}

// App Services

module apim './modules/apim/apim.bicep' = {
  name: 'apim'
  scope: appResourceGroup
  params: {
    name: !empty(apimServiceName) ? apimServiceName : '${abbrs.apiManagementService}${environmentName}-${resourceToken}'
    location: location
    tags: tags
    applicationInsightsId: monitor.outputs.applicationInsightsId
    applicationInsightsInstrumentationKey: monitor.outputs.applicationInsightsInstrumentationKey
    sharedResourceGroupName: sharedResourceGroup.name
    keyVaultName: keyVault.outputs.keyVaultName
    logAnalyticsWorkspaceId: monitor.outputs.logAnalyticsWorkspaceId
  }
}

module cosmosDb './modules/cosmosdb/cosmosdb.bicep' = {
  name: 'cosmosdb'
  scope: appResourceGroup
  params: {
    name: !empty(cosmosDbAccountName) ? cosmosDbAccountName : '${abbrs.documentDBDatabaseAccounts}${environmentName}-${resourceToken}'
    location: location
    tags: tags
    sharedResourceGroupName: sharedResourceGroup.name
    keyVaultName: keyVault.outputs.keyVaultName
    logAnalyticsWorkspaceId: monitor.outputs.logAnalyticsWorkspaceId
  }
}

module appServices './modules/app/app.bicep' = {
  name: 'app-services'
  scope: appResourceGroup
  params: {
    location: location
    tags: tags
    appServiceName: !empty(appServiceName) ? appServiceName : '${abbrs.webSitesAppService}${environmentName}-${resourceToken}'
    appServicePlanName: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${abbrs.webSitesAppService}${environmentName}-${resourceToken}'
    sharedResourceGroupName: sharedResourceGroup.name
    keyVaultName: keyVault.outputs.keyVaultName
    appInsightsConnectionString: monitor.outputs.applicationInsightsConnectionString
    appInsightsInstrumentationKey: monitor.outputs.applicationInsightsInstrumentationKey
    logAnalyticsWorkspaceId: monitor.outputs.logAnalyticsWorkspaceId
    azureOpenaiEndpoint: ai.outputs.openAiUri
    azureOpenaiApiVersion: ai.outputs.openAiApiVersion
    azureOpenaiApiModel: ai.outputs.openAiChatModel
    azureOpenaiApiModelEmbedding: ai.outputs.openAiEmbeddingModel
    azureOpenaiApiKey: ai.outputs.openAiSecretReference
    azureSearchEndpoint: ai.outputs.cognitiveSearchUri
    azureSearchApiVersion: ai.outputs.cognitiveSearchApiVersion
    azureSearchIndexName: ai.outputs.cognitiveSearchIndex
    azureSearchApiKey: ai.outputs.cognitiveSearchSecretReferenceApiKey
    azureSearchAdminKey: ai.outputs.cognitiveSearchSecretReferenceAdminKey
    storageConnectionString: storageAccount.outputs.secretReference
    azureCosmosEndpoint: cosmosDb.outputs.uri
    azureCosmosDatabase: cosmosDb.outputs.database
    azureCosmosContainer: cosmosDb.outputs.container
    azureCosmosKey: cosmosDb.outputs.secretReference
    apimServiceName: apim.outputs.name
  }
}

// AI Services

module ai 'modules/ai/ai.bicep' = {
  name: 'ai'
  scope: aiResourceGroup
  params: {
    openAiName: !empty(openAiServiceName) ? openAiServiceName : '${abbrs.cognitiveServicesOpenAi}${environmentName}-${resourceToken}'
    cognitiveSearchName: !empty(cognitiveSearchServiceName) ? cognitiveSearchServiceName : '${abbrs.searchSearchServices}${environmentName}-${resourceToken}'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: monitor.outputs.logAnalyticsWorkspaceId
    appResourceGroupName: appResourceGroup.name
    sharedResourceGroupName: sharedResourceGroup.name
    apimServiceName: apim.outputs.name
    keyVaultName: keyVault.outputs.keyVaultName
    keyVaultEndpoint: keyVault.outputs.keyVaultEndpoint
  }
}

// Output environment variables for local development and testing

output AZURE_RESOURCE_GROUP string = appResourceGroup.name
output AZURE_OPENAI_ENDPOINT string = ai.outputs.openAiUri
output AZURE_OPENAI_API_VERSION string = ai.outputs.openAiApiVersion
output AZURE_OPENAI_API_MODEL_CHAT string = ai.outputs.openAiChatModel
output AZURE_OPENAI_API_MODEL_EMBEDDING string = ai.outputs.openAiEmbeddingModel
output AZURE_SEARCH_ENDPOINT string = ai.outputs.cognitiveSearchUri
output AZURE_SEARCH_API_VERSION string = ai.outputs.cognitiveSearchApiVersion
output AZURE_SEARCH_INDEX_NAME string = ai.outputs.cognitiveSearchIndex
output AZURE_COSMOS_ENDPOINT string = cosmosDb.outputs.uri
output AZURE_COSMOS_DATABASE string = cosmosDb.outputs.database
output AZURE_COSMOS_CONTAINER string = cosmosDb.outputs.container
