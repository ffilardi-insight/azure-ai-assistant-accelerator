param name string
param location string = resourceGroup().location
param tags object = {}
param appSettings object = {}
param servicePlanId string
param kind string = 'app,linux'
param linuxFxVersion string = 'PYTHON|3.11'
param appCommandLine string = 'python -m uvicorn main:app --host 0.0.0.0'
param ftpsState string = 'Disabled'
param allowFtpPublishing bool = false
param allowScmPublishing bool = true
param buildOnDeployment string = 'true'
param httpsOnly bool = true
param logLevel string = 'Information'
param logAnalyticsWorkspaceId string = ''
param enableLogs bool = true
param enableAuditLogs bool = false
param enableMetrics bool = true
param clientAffinityEnabled bool = false
param clientCertEnabled bool = false
param clientCertMode string = 'Required'
param alwaysOn bool = false
param publicNetworkAccess string = 'Enabled'
param healthCheckPath string = '/ping'

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: name
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
      healthCheckPath: healthCheckPath
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

  resource logs 'config' = {
    name: 'logs'
    properties: {
      applicationLogs: {
        fileSystem: {
          level: logLevel
        }
      }
      detailedErrorMessages: {
        enabled: true
      }
      failedRequestsTracing: {
        enabled: true
      }
      httpLogs: {
        fileSystem: {
          enabled: true
          retentionInDays: 1
          retentionInMb: 35
        }
      }
    }
  }
}

resource ftpBasicPublishingCred 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-01-01' = {
  parent: appService
  name: 'ftp'
  properties: {
    allow: allowFtpPublishing
  }
}

resource scmBasicPublishingCred 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-01-01' = {
  parent: appService
  name: 'scm'
  properties: {
    allow: allowScmPublishing
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'Logging'
  scope: appService
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: enableLogs
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: enableLogs
      }
      {
        category: 'AppServiceAppLogs'
        enabled: enableLogs
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: enableLogs
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: enableAuditLogs
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: enableAuditLogs
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: enableMetrics
      }
    ]
  }
}

output id string = appService.id
output name string = appService.name
output url string = 'https://${appService.properties.defaultHostName}/'
output principalId string = appService.identity.principalId
