// ============================================================================
// Azure Container Registry Module
// Creates an ACR instance with admin access disabled (use managed identity)
// ============================================================================

@description('Name of the Container Registry')
param containerRegistryName string

@description('Azure region for deployment')
param location string

// ---------------------------------------------------------------------------
// Container Registry
// Admin user disabled per security best practices; use managed identity
// ---------------------------------------------------------------------------
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: containerRegistryName
  location: location
  tags: {
    SecurityControl: 'Ignore'
  }
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
output containerRegistryId string = containerRegistry.id
output containerRegistryName string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer
