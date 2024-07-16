param name string
param location string = resourceGroup().location
param tags object = {}
param sku string = 'PerGB2018'
param publicNetworkAccessForQuery string = 'Enabled'
param publicNetworkAccessForIngestion string = 'Enabled'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': name })
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: sku
    }
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
  })
}

output id string = logAnalytics.id
output name string = logAnalytics.name
