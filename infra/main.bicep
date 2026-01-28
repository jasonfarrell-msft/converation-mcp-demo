
targetScope = 'resourceGroup'

param appName string

param location string = resourceGroup().location
param suffix string = 'jx01'

var shortLocationMap = {
  eastus: 'eus'
  westus: 'wus'
  centralus: 'cus'
  eastus2: 'eus2'
  westus2: 'wus2'
  northcentralus: 'ncus'
  southcentralus: 'scus'
}

// Storage Account for Foundry
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${replace(appName, '-', '')}${shortLocationMap[location]}${suffix}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    supportsHttpsTrafficOnly: true
  }
  tags: {
    SecurityControl: 'Ignore'
  }
}

// Application Insights for Foundry
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${appName}-${shortLocationMap[location]}-${suffix}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

// Azure AI Foundry Hub
resource foundryHub 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: 'foundry-${appName}-${shortLocationMap[location]}-${suffix}'
  kind: 'AIServices'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: 'foundry-${appName}-${shortLocationMap[location]}-${suffix}'
    publicNetworkAccess: 'Enabled'
    allowProjectManagement: true
  }
  tags: {
    SecurityControl: 'Ignore'
  }
}

// Foundry Project
resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  name: 'main-project'
  parent: foundryHub
  location: location
  properties: {}
}

// Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: 'cr${replace(appName, '-', '')}${shortLocationMap[location]}${suffix}'
  location: location
  sku: {
    name: 'Standard'
  }
}

// Container Apps Environment
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'cae-${appName}-${shortLocationMap[location]}-${suffix}'
  location: location
  properties: {
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

// Container App
resource ApiContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'aca-${appName}-${shortLocationMap[location]}-${suffix}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    environmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: 'system'
        }
      ]
    }
    template: {
      containers: [
        {
          name: appName
          image: 'nginx:latest'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}

// ACR Pull Role Assignment for System Assigned Identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, ApiContainerApp.id, 'AcrPull')
  scope: containerRegistry
  properties: {
    principalId: ApiContainerApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

// MCP Container App
resource McpContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'aca-mcp-${appName}-${shortLocationMap[location]}-${suffix}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    environmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: 'system'
        }
      ]
    }
    template: {
      containers: [
        {
          name: appName
          image: 'nginx:latest'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}

// ACR Pull Role Assignment for MCP Container App
resource mcpAcrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, McpContainerApp.id, 'AcrPull')
  scope: containerRegistry
  properties: {
    principalId: McpContainerApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}
