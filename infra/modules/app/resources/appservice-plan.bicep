param name string
param location string = resourceGroup().location
param tags object = {}
param sku string = 'Basic'
param skuCode string = 'B1'
param kind string = 'linux'
param zoneRedundant bool = false
param reserved bool = true

resource servicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': name })
  sku: {
    name: skuCode
    tier: sku
  }
  kind: kind
  properties: {
    reserved: reserved
    zoneRedundant: zoneRedundant
  }
}

output id string = servicePlan.id
