// ============================================================================
// Azure API Center Module
// Creates an API Center instance and registers N MCP servers as MCP assets
// ============================================================================

@description('Name of the API Center instance')
param apiCenterName string

@description('Azure region for deployment')
param location string

@description('APIM gateway URL used as the MCP server runtime endpoint')
param apimGatewayUrl string

@description('Collection of MCP servers to register in API Center')
param mcpServers array

resource apiCenter 'Microsoft.ApiCenter/services@2024-06-01-preview' = {
  name: apiCenterName
  location: location
  sku: {
    name: 'Standard'
  }
  tags: {
    SecurityControl: 'Ignore'
  }
}

// ---------------------------------------------------------------------------
// Default workspace (required parent for APIs)
// ---------------------------------------------------------------------------
resource defaultWorkspace 'Microsoft.ApiCenter/services/workspaces@2024-06-01-preview' = {
  parent: apiCenter
  name: 'default'
  properties: {
    title: 'Default'
    description: 'Default workspace'
  }
}

// ---------------------------------------------------------------------------
// Environment: APIM-hosted MCP endpoint
// ---------------------------------------------------------------------------
resource apimEnvironment 'Microsoft.ApiCenter/services/workspaces/environments@2024-06-01-preview' = {
  parent: defaultWorkspace
  name: 'apim-mcp-environment'
  properties: {
    title: 'APIM MCP Gateway'
    description: 'Azure API Management gateway fronting MCP servers'
    kind: 'production'
    server: {
      type: 'Azure API Management'
      managementPortalUri: [
        apimGatewayUrl
      ]
    }
  }
}

// ---------------------------------------------------------------------------
// APIs: MCP Servers (kind: mcp)
// ---------------------------------------------------------------------------
resource mcpApis 'Microsoft.ApiCenter/services/workspaces/apis@2024-06-01-preview' = [
  for server in mcpServers: {
    parent: defaultWorkspace
    name: server.name
    properties: {
      title: server.displayName
      description: server.description
      kind: 'mcp'
      summary: server.description
    }
  }
]

// ---------------------------------------------------------------------------
// API Versions
// ---------------------------------------------------------------------------
resource mcpVersions 'Microsoft.ApiCenter/services/workspaces/apis/versions@2024-06-01-preview' = [
  for (server, i) in mcpServers: {
    parent: mcpApis[i]
    name: 'v1-0-0'
    properties: {
      title: '1.0.0'
      lifecycleStage: 'production'
    }
  }
]

// ---------------------------------------------------------------------------
// API Definitions
// ---------------------------------------------------------------------------
resource mcpDefinitions 'Microsoft.ApiCenter/services/workspaces/apis/versions/definitions@2024-06-01-preview' = [
  for (server, i) in mcpServers: {
    parent: mcpVersions[i]
    name: '${server.name}-definition'
    properties: {
      title: '${server.displayName} Definition'
      description: 'Definition for ${server.displayName} version 1.0.0'
    }
  }
]

// ---------------------------------------------------------------------------
// Deployments: link each API to the APIM environment with runtime URL
// ---------------------------------------------------------------------------
resource mcpDeployments 'Microsoft.ApiCenter/services/workspaces/apis/deployments@2024-06-01-preview' = [
  for (server, i) in mcpServers: {
    parent: mcpApis[i]
    name: '${server.name}-deployment'
    properties: {
      title: '${server.displayName} Deployment'
      description: '${server.displayName} accessible via APIM gateway'
      environmentId: '/workspaces/${defaultWorkspace.name}/environments/${apimEnvironment.name}'
      definitionId: '/workspaces/${defaultWorkspace.name}/apis/${mcpApis[i].name}/versions/${mcpVersions[i].name}/definitions/${mcpDefinitions[i].name}'
      server: {
        runtimeUri: [
          '${apimGatewayUrl}/${server.path}'
        ]
      }
      state: 'active'
    }
  }
]

output apiCenterName string = apiCenter.name
