param apimServiceName string
param backendUrl string
param backendResourceId string

var apiName = 'ai-assistant'
var apiDisplay = 'AI Assistant'
var apiDescription = 'Azure AI Assistant API Backend Services'
var apiPath = 'assistant'
var apiDefinition = string(loadJsonContent('appservice-api.json'))
var apiDefinitionFormat = 'openapi+json'
var apiVersionSetId = 'assistant-versionset'
var apiVersion = 'v1'
var apiRevision = '1'
var apiProductName = 'Assistant'
var apiProductId = 'assistant-product'
var apiBackendId = 'assistant-backend'
var subscriptionId = 'assistant-subscription'

var apiPolicyDefinition = loadTextContent('../policy/appservice-api-policy.xml')
var apiPolicyFormat = 'rawxml'

resource apimService 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimServiceName
}

resource apiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2023-05-01-preview' = {
  name: apiVersionSetId
  parent: apimService
  properties: {
    displayName: apiDisplay
    versioningScheme: 'Segment'
    description: apiDescription
  }
}

resource backend 'Microsoft.ApiManagement/service/backends@2021-08-01' = {
  name: apiBackendId
  parent: apimService
  properties: {
    description: apiDescription
    url: backendUrl
    resourceId: replace('${az.environment().resourceManager}/${backendResourceId}', '///', '/')
    protocol: 'http'
    tls: {
      validateCertificateChain: false
      validateCertificateName: false
    }
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2023-09-01-preview' = {
  name: apiName
  parent: apimService
  properties: {
    path: apiPath
    displayName: apiDisplay
    apiRevision: apiRevision
    apiVersion: apiVersion
    apiVersionSetId: apiVersionSet.id
    isCurrent: true
    subscriptionRequired: true
    format: apiDefinitionFormat
    value: apiDefinition
    protocols: [
      'https'
    ]
  }
  dependsOn: [
    backend
  ]
}

resource product 'Microsoft.ApiManagement/service/products@2023-05-01-preview' = {
  name: apiProductId
  parent: apimService
  properties: {
    description: apiDescription
    displayName: apiProductName
    state: 'published'
    subscriptionRequired: true
  }
}

resource productLink 'Microsoft.ApiManagement/service/products/apiLinks@2023-05-01-preview' = {
  name: '${apiProductId}-link'
  parent: product
  properties: {
    apiId: api.id
  }
}

resource subscription 'Microsoft.ApiManagement/service/subscriptions@2023-09-01-preview' = {
  name: subscriptionId
  parent: apimService
  properties: {
    scope: product.id
    displayName: apiDisplay
    state: 'active'
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2022-08-01' = {
  name: 'policy'
  parent: api
  properties: {
    value: apiPolicyDefinition
    format: apiPolicyFormat
  }
  dependsOn: [
    backend
  ]
}
