param name string
param location string = resourceGroup().location
param tags object = {}
param logAnalyticsWorkspaceId string = ''

module vault './resources/vault.bicep' = {
  name: 'vault'
  params: {
    name: name
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

output keyVaultId string = vault.outputs.id
output keyVaultName string = vault.outputs.name
output keyVaultEndpoint string = vault.outputs.uri
