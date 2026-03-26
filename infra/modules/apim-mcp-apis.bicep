// ============================================================================
// APIM MCP APIs Module
// Creates MCP-typed APIs in an existing APIM instance, referencing
// backends that must already exist. Deployed as a separate ARM deployment
// to ensure backends are fully registered before APIs reference them.
// ============================================================================

@description('Name of the existing API Management instance')
param apimName string

@description('Collection of MCP servers to register as APIs')
param mcpServers array

resource apim 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apimName
}

// ---------------------------------------------------------------------------
// MCP Servers (dedicated MCP type in APIM)
// Registered under APIs > MCP Servers in the portal
// Uses backendId — required for MCP-typed APIs
// ---------------------------------------------------------------------------
resource mcpApis 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = [
  for server in mcpServers: {
    parent: apim
    name: server.name
    properties: {
      type: 'mcp'
      displayName: server.displayName
      description: server.description
      path: server.path
      protocols: [
        'https'
      ]
      subscriptionRequired: false
      backendId: '${server.name}-backend'
    }
  }
]
