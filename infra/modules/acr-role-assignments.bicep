// ============================================================================
// ACR Role Assignments Module
// Grants AcrPull role to the shared User-Assigned Managed Identity
// ============================================================================

@description('Name of the Container Registry')
param containerRegistryName string

@description('Principal ID of the User-Assigned Managed Identity')
param uaiPrincipalId string

// ---------------------------------------------------------------------------
// Reference the existing Container Registry
// ---------------------------------------------------------------------------
resource existingRegistry 'Microsoft.ContainerRegistry/registries@2025-11-01' existing = {
  name: containerRegistryName
}

// AcrPull built-in role definition ID
var acrPullRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)

// ---------------------------------------------------------------------------
// AcrPull for User-Assigned Managed Identity
// ---------------------------------------------------------------------------
resource acrPullRoleUai 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(existingRegistry.id, acrPullRoleDefinitionId, uaiPrincipalId)
  scope: existingRegistry
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: uaiPrincipalId
    principalType: 'ServicePrincipal'
  }
}
