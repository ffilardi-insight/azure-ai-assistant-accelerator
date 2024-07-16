param location string = resourceGroup().location
param tags object = {}
param appSettings object = {}
param appServiceName string
param servicePlanId string
param kind string = 'app,linux'
param linuxFxVersion string = 'PYTHON|3.11'
param appCommandLine string = 'python -m uvicorn main:app --host 0.0.0.0'
param ftpsState string = 'Disabled'
param buildOnDeployment string = 'false'
param httpsOnly bool = true
param clientAffinityEnabled bool = false
param clientCertEnabled bool = false
param clientCertMode string = 'Required'
param alwaysOn bool = true
param publicNetworkAccess string = 'Enabled'

resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

resource appServiceSlot 'Microsoft.Web/sites/slots@2023-01-01' = {
  parent: appService
  name: 'staging'
  location: location
  tags: tags
  kind: kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: servicePlanId
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appCommandLine: appCommandLine
      ftpsState: ftpsState
      alwaysOn: alwaysOn
    }
    httpsOnly: httpsOnly
    clientAffinityEnabled: clientAffinityEnabled
    clientCertEnabled: clientCertEnabled
    clientCertMode: clientCertMode
    publicNetworkAccess: publicNetworkAccess
  }

  resource settings 'config' = {
    name: 'appsettings'
    properties: union(appSettings, {
      SCM_DO_BUILD_DURING_DEPLOYMENT: buildOnDeployment
    })
  }
}
