param openAiName string
param cognitiveSearchName string
param location string = resourceGroup().location
param tags object = {}
param logAnalyticsWorkspaceId string = ''
param appResourceGroupName string
param sharedResourceGroupName string
param apimServiceName string
param keyVaultName string
param keyVaultEndpoint string

module openAi './resources/openai.bicep' = {
  name: 'openai-service'
  params: {
    name: openAiName
    location: location
    tags: tags
    keyVaultName: keyVaultName
    sharedResourceGroupName: sharedResourceGroupName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

module openAiApi '../apim/api/openai-api.bicep' = if (apimServiceName != '') {
  name: 'openai-api'
  scope: resourceGroup(appResourceGroupName)
  params: {
    apimServiceName: apimServiceName
    backendUrl: openAi.outputs.uri
    keyVaultEndpoint: keyVaultEndpoint
    keyVaultSecretName: openAi.outputs.secretName
  }
}

module cognitiveSearch './resources/cognitivesearch.bicep' = {
  name: 'cognitivesearch-service'
  params: {
    name: cognitiveSearchName
    location: location
    tags: tags
    keyVaultName: keyVaultName
    sharedResourceGroupName: sharedResourceGroupName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

output openAiUri string = openAi.outputs.uri
output openAiChatModel string = openAi.outputs.chatModel
output openAiEmbeddingModel string = openAi.outputs.embeddingModel
output openAiApiVersion string = openAi.outputs.apiVersion
output openAiSecretReference string = openAi.outputs.secretReference
output openAiSecretName string = openAi.outputs.secretName
output cognitiveSearchUri string = cognitiveSearch.outputs.uri
output cognitiveSearchSecretReferenceApiKey string = cognitiveSearch.outputs.secretReferenceApiKey
output cognitiveSearchSecretReferenceAdminKey string = cognitiveSearch.outputs.secretReferenceAdminKey
output cognitiveSearchApiVersion string = cognitiveSearch.outputs.apiVersion
output cognitiveSearchIndex string = cognitiveSearch.outputs.indexName
