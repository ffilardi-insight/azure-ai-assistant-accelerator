param name string
param location string = resourceGroup().location
param tags object = {}
param sharedResourceGroupName string
param keyVaultName string
param logAnalyticsWorkspaceId string = ''

module cosmosDb './resources/account.bicep' = {
  name: 'cosmosdb-account'
  params: {
    name: name
    location: location
    tags: tags
    sharedResourceGroupName: sharedResourceGroupName
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

output id string = cosmosDb.outputs.id
output name string = cosmosDb.outputs.name
output uri string = cosmosDb.outputs.uri
output secretReference string = cosmosDb.outputs.secretReference
output database string = cosmosDb.outputs.database
output container string = cosmosDb.outputs.container
