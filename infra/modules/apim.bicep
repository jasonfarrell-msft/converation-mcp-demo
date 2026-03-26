// ============================================================================
// Azure API Management
// Developer SKU instance
// ============================================================================

@description('Name of the API Management instance')
param apimName string

@description('Azure region for deployment')
param location string

@description('Publisher email for APIM')
param publisherEmail string

@description('Publisher organization name for APIM')
param publisherName string

resource apim 'Microsoft.ApiManagement/service@2024-06-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

output apimGatewayUrl string = apim.properties.gatewayUrl
output apimName string = apim.name
