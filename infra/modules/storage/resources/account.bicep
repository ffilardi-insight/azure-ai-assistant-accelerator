
param name string
param location string = resourceGroup().location
param tags object = {}
param kind string = 'StorageV2'
param sku string = 'Standard_LRS'
param publicNetworkAccess string = 'Enabled'
param minimumTlsVersion string = 'TLS1_2'
param supportsHttpsTrafficOnly bool = true
param allowBlobPublicAccess bool = false
param allowSharedKeyAccess bool = true
param defaultOAuth bool = false
param allowedCopyScope string = 'PrivateLink'
param accessTier string = 'Hot'
param allowCrossTenantReplication bool = false
param networkAclsBypass string = 'AzureServices'
param networkAclsDefaultAction string = 'Allow'
param networkAclsVirtualNetworkRules array = []
param networkAclsIpRules array = []
param dnsEndpointType string = 'Standard'
param isHnsEnabled bool = false
param isSftpEnabled bool = false
param keySource string = 'Microsoft.Storage'
param encryptionEnabled bool = true
param infrastructureEncryptionEnabled bool = false
param sharedResourceGroupName string
param keyVaultName string

var keyVaultSecretName = 'storage-connection-string'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': name })
  kind: kind
  sku: {
    name: sku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    minimumTlsVersion: minimumTlsVersion
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    defaultToOAuthAuthentication: defaultOAuth
    allowedCopyScope: allowedCopyScope
    accessTier: accessTier
    publicNetworkAccess: publicNetworkAccess
    allowCrossTenantReplication: allowCrossTenantReplication
    networkAcls: {
      bypass: networkAclsBypass
      defaultAction: networkAclsDefaultAction
      virtualNetworkRules: networkAclsVirtualNetworkRules
      ipRules: networkAclsIpRules
    }
    dnsEndpointType: dnsEndpointType
    isHnsEnabled: isHnsEnabled
    isSftpEnabled: isSftpEnabled
    encryption: {
      keySource: keySource
      services: {
        blob: {
          enabled: encryptionEnabled
        }
      }
      requireInfrastructureEncryption: infrastructureEncryptionEnabled
    }
  }
}

module keyVaultSecret '../../keyvault/config/secret.bicep' = {
  name: 'storage-account-secret'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    secretName: keyVaultSecretName
    secretValue: 'DefaultEndpointsProtocol=https;AccountName=${name};AccountKey=${storageAccount.listKeys(storageAccount.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  }
}

output id string = storageAccount.id
output name string = storageAccount.name
output secretReference string = keyVaultSecret.outputs.secretReference
