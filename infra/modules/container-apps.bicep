// ============================================================================
// Azure Container Apps Module
// Creates a Container App Environment and two Container Apps (API and MCP)
// Uses managed identity for ACR image pulls
// ============================================================================

@description('Name of the Container App Environment')
param containerAppEnvironmentName string

@description('Name of the API Container App')
param containerAppApiName string

@description('Name of the MCP Container App')
param containerAppMcpName string

@description('Azure region for deployment')
param location string

// ---------------------------------------------------------------------------
// Container App Environment
// ---------------------------------------------------------------------------
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2025-07-01' = {
  name: containerAppEnvironmentName
  location: location
  tags: {
    SecurityControl: 'Ignore'
  }
  properties: {
    zoneRedundant: false
  }
}

// ---------------------------------------------------------------------------
// API Container App
// ---------------------------------------------------------------------------
resource containerAppApi 'Microsoft.App/containerApps@2025-07-01' = {
  name: containerAppApiName
  location: location
  tags: {
    SecurityControl: 'Ignore'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
      }
    }
    template: {
      containers: [
        {
          name: 'api'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
    }
  }
}

// ---------------------------------------------------------------------------
// MCP Container App
// ---------------------------------------------------------------------------
resource containerAppMcp 'Microsoft.App/containerApps@2025-07-01' = {
  name: containerAppMcpName
  location: location
  tags: {
    SecurityControl: 'Ignore'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
      }
    }
    template: {
      containers: [
        {
          name: 'mcp'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
output containerAppEnvironmentId string = containerAppEnvironment.id
output apiAppId string = containerAppApi.id
output apiAppFqdn string = containerAppApi.properties.configuration.ingress.fqdn
output apiPrincipalId string = containerAppApi.identity.principalId
output mcpAppId string = containerAppMcp.id
output mcpAppFqdn string = containerAppMcp.properties.configuration.ingress.fqdn
output mcpPrincipalId string = containerAppMcp.identity.principalId
