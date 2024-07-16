#!/bin/bash

# Script: load-env-secrets.sh
#
# Description: This script loads secrets from Azure Key Vault and sets them as local environment variables.
#
# Usage: load-env-secrets.sh <keyVaultName> <keyVaultResourceGroupName>
#
# Arguments:
#   - keyVaultName: The name of the Azure Key Vault.
#   - keyVaultResourceGroupName: The resource group name of the Azure Key Vault.
#
# Example: load-env-secrets.sh my-kv-name my-kv-resourcegroup

# Capture command-line parameters
keyVaultName="$1"
keyVaultResourceGroupName="$2"

# Check if the required arguments are provided
if [[ -z "$keyVaultName" || -z "$keyVaultResourceGroupName" ]]; then
    echo "Usage: $0 <keyVaultName> <keyVaultResourceGroupName>"
    exit 1
fi

# Get the current user's object ID
userPrincipalName="$(az account show --query user.name -o tsv)"

# Assign "Key Vault Secrets Officer" role to the current user for the Key Vault
az role assignment create --assignee "$userPrincipalName" --role "Key Vault Secrets Officer" --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$keyVaultResourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName" --output none

if [ $? -eq 0 ]; then
    # Sleep for 5 seconds to allow the role assignment to propagate
    sleep 5
    echo "Role 'Key Vault Secrets Officer' assigned to $userPrincipalName for Key Vault '$keyVaultName'"
else
    echo "Role assignment failed"
    exit 1
fi

# Set local environment variables
azd env set AZURE_OPENAI_API_KEY $(az keyvault secret show --name "openai-api-key" --vault-name $keyVaultName --query value -o tsv)
azd env set AZURE_SEARCH_API_KEY $(az keyvault secret show --name "cognitivesearch-api-key" --vault-name $keyVaultName --query value -o tsv)
azd env set AZURE_SEARCH_ADMIN_KEY $(az keyvault secret show --name "cognitivesearch-admin-key" --vault-name $keyVaultName --query value -o tsv)
azd env set AZURE_STORAGE_CONNECTION_STRING $(az keyvault secret show --name "storage-connection-string" --vault-name $keyVaultName --query value -o tsv)
azd env set AZURE_COSMOS_KEY $(az keyvault secret show --name "cosmosdb-key" --vault-name $keyVaultName --query value -o tsv)

echo "Local environment variables updated successfully"
