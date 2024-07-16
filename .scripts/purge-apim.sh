#!/bin/bash

# Script: purge-apim.sh
#
# Description: This script purges an Azure API Management service.
#
# Usage: purge-apim.sh <resourceName> <resourceLocation>
#
# Arguments:
#   - resourceName: The name of the Azure API Management service.
#   - resourceLocation: The location of the Azure API Management service.
#
# Example: purge-apim.sh my-apim westus

# Capture command-line parameters
resourceName="$1"
resourceLocation="$2"

# Check if the required arguments are provided
if [[ -z "$resourceName" || -z "$resourceLocation" ]]; then
    echo "Usage: $0 <resourceName> <resourceLocation>"
    exit 1
fi

# Get the current subscription ID
subscriptionId=$(az account show --query id -o tsv)

# Get an access token
token=$(az account get-access-token --query accessToken -o tsv)

# Construct the URI
uri="https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.ApiManagement/locations/$location/deletedservices/$apimName/?api-version=2020-12-01"

# Make the HTTP DELETE request
curl -X DELETE "$uri" -H "Authorization: Bearer $token"

# Check the exit status of the curl command
if [[ $? -eq 0 ]]; then
    echo "API Management service $resourceName in $resourceLocation has been purged successfully"
else
    echo "API Management purging failed"
    exit 1
fi