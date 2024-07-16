param name string
param location string = resourceGroup().location
param tags object = {}
param logAnalyticsWorkspaceId string = ''
param applicationInsightsId string = ''
param applicationInsightsInstrumentationKey string = ''
param keyVaultName string
param sharedResourceGroupName string

// Standard role definition: Key Vault Secrets User
var keyVaultRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'

module apimService './resources/apim-service.bicep' = {
  name: 'apim-service'
  params: {
    name: name
    location: location
    tags: tags
    applicationInsightsId: applicationInsightsId
    applicationInsightsInstrumentationKey: applicationInsightsInstrumentationKey
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

module roleAssignment '../keyvault/config/role-assignment.bicep' = {
  name: 'apim-role-assignment'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    principalId: apimService.outputs.principalId
    roleDefinitionId: keyVaultRoleDefinitionId
    serviceId: apimService.outputs.id
    keyVaultName: keyVaultName
  }
}

output id string = apimService.outputs.id
output name string = apimService.outputs.name
output proxyHostName string = apimService.outputs.proxyHostName
output developerPortalHostName string = apimService.outputs.developerPortalHostName
