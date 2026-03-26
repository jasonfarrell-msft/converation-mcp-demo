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

@description('Container image for the API app')
param apiImageName string

@description('Container image for the MCP app')
param mcpImageName string

@description('Resource ID of the User-Assigned Managed Identity for ACR pull')
param userAssignedIdentityId string

@description('Login server of the Container Registry (e.g. myacr.azurecr.io)')
param containerRegistryServer string

@description('Foundry project endpoint for the API app')
param foundryProjectEndpoint string

@description('Agent name for the API app')
param agentName string

@description('SQL Server FQDN for the MCP app')
param sqlServerFqdn string

@description('SQL Database name for the MCP app')
param sqlDatabaseName string

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
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      registries: [
        {
          server: containerRegistryServer
          identity: userAssignedIdentityId
        }
      ]
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
        corsPolicy: {
          allowedOrigins: [
            'http://localhost:8080'
          ]
          allowedMethods: [
            '*'
          ]
          allowedHeaders: [
            '*'
          ]
        }
      }
    }
    template: {
      containers: [
        {
          name: 'api'
          image: apiImageName
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'FoundryEndpoint'
              value: foundryProjectEndpoint
            }
            {
              name: 'AgentName'
              value: agentName
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
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
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      registries: [
        {
          server: containerRegistryServer
          identity: userAssignedIdentityId
        }
      ]
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
          image: mcpImageName
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'SqlServer'
              value: sqlServerFqdn
            }
            {
              name: 'SqlDatabase'
              value: sqlDatabaseName
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
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
