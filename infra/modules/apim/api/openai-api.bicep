param apimServiceName string
param backendUrl string
param keyVaultEndpoint string
param keyVaultSecretName string

var apiName = 'openai-service-api'
var apiDisplay = 'OpenAI API'
var apiDescription = 'Azure OpenAI Service API'
var apiPath = 'openai'
var apiDefinition = string(loadJsonContent('openai-api.json'))
var apiDefinitionFormat = 'openapi+json'
var apiVersionSetId = 'openai-api-versionset'
var apiVersion = 'v1'
var apiRevision = '1'
var apiProductId = 'openai-product'
var apiProductName = 'OpenAI'
var apiBackendId = 'openai-backend'
var apiOperationId = 'chat_completions'
var subscriptionId = 'openai-subscription'

resource  apimService 'Microsoft.ApiManagement/service@2021-08-01' existing = {
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

resource namedValue 'Microsoft.ApiManagement/service/namedValues@2022-08-01' = {
  name: keyVaultSecretName
  parent: apimService
  properties: {
    displayName: keyVaultSecretName
    secret: true
    keyVault:{
      secretIdentifier: '${keyVaultEndpoint}secrets/${keyVaultSecretName}'
    }
  }
}

resource backend 'Microsoft.ApiManagement/service/backends@2021-08-01' = {
  name: apiBackendId
  parent: apimService
  properties: {
    description: apiDescription
    url: '${backendUrl}openai/'
    protocol: 'http'
    tls: {
      validateCertificateChain: false
      validateCertificateName: false
    }
    credentials: {
      header: {
        'api-key': [
          '{{${namedValue.name}}}'
        ]
      }
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
    value: loadTextContent('../policy/openai-api-policy.xml')
    format: 'rawxml'
  }
  dependsOn: [
    backend
    namedValue
  ]
}

resource operation 'Microsoft.ApiManagement/service/apis/operations@2020-06-01-preview' existing = {
  name: apiOperationId
  parent: api
}

resource operationPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2022-08-01' = {
  name: 'policy'
  parent: operation
  properties: {
    value: loadTextContent('../policy/openai-api-operation-policy.xml')
    format: 'rawxml'
  }
}
