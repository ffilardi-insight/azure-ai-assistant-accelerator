param name string
param location string = resourceGroup().location
param tags object = {}
param sharedResourceGroupName string
param keyVaultName string
param logAnalyticsWorkspaceId string = ''

module account './resources/account.bicep' = {
  name: '${name}-deployment'
  params: {
    name: name
    location: location
    tags: tags
    sharedResourceGroupName: sharedResourceGroupName
    keyVaultName: keyVaultName
  }
}

module blob './resources/blob.bicep' = {
  name: '${name}-blob-deployment'
  params: {
    storageAccountName: account.outputs.name
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

output id string = account.outputs.id
output name string = account.outputs.name
output secretReference string = account.outputs.secretReference
