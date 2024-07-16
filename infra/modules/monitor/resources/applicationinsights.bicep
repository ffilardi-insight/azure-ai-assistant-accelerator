param name string
param location string = resourceGroup().location
param tags object = {}
param dashboardName string
param logAnalyticsWorkspaceId string = ''
param publicNetworkAccessForQuery string = 'Enabled'
param publicNetworkAccessForIngestion string = 'Enabled'
param kind string = 'web'

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': name })
  kind: kind
  properties: {
    Application_Type: kind
    WorkspaceResourceId: logAnalyticsWorkspaceId
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
  }
}

module applicationInsightsDashboard 'applicationinsights-dashboard.bicep' = {
  name: 'application-insights-dashboard'
  params: {
    name: dashboardName
    location: location
    applicationInsightsName: applicationInsights.name
  }
}

output connectionString string = applicationInsights.properties.ConnectionString
output instrumentationKey string = applicationInsights.properties.InstrumentationKey
output appInsightsId string = applicationInsights.id
output appInsightsName string = applicationInsights.name
output dashboardName string = applicationInsightsDashboard.outputs.dashboardName
