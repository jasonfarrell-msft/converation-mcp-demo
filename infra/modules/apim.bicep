// ============================================================================
// Azure API Management
// Developer SKU instance with MCP Server Backends
// MCP APIs are deployed separately via apim-mcp-apis.bicep to ensure
// backends are fully registered before APIs reference them
// ============================================================================

@description('Name of the API Management instance')
param apimName string

@description('Azure region for deployment')
param location string

@description('Publisher email for APIM')
param publisherEmail string

@description('Publisher organization name for APIM')
param publisherName string

@description('Collection of MCP servers to register in APIM')
param mcpServers array

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

// ---------------------------------------------------------------------------
// MCP Server Backends
// ---------------------------------------------------------------------------
resource mcpBackends 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = [
  for server in mcpServers: {
    parent: apim
    name: '${server.name}-backend'
    properties: {
      protocol: 'http'
      url: 'https://${server.fqdn}'
      description: '${server.displayName} hosted on Azure Container Apps'
    }
  }
]

output apimGatewayUrl string = apim.properties.gatewayUrl
output apimName string = apim.name
