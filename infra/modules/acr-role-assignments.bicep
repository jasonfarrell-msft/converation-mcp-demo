// ============================================================================
// ACR Role Assignments Module
// Grants AcrPull role to Container App managed identities
// Separated into a module to resolve deploy-time constant requirements
// ============================================================================

@description('Name of the Container Registry')
param containerRegistryName string

@description('Principal ID of the API Container App managed identity')
param apiPrincipalId string

@description('Principal ID of the MCP Container App managed identity')
param mcpPrincipalId string

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
// AcrPull for API Container App
// ---------------------------------------------------------------------------
resource acrPullRoleApi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, containerRegistryName, 'api-acrpull')
  scope: existingRegistry
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: apiPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// AcrPull for MCP Container App
// ---------------------------------------------------------------------------
resource acrPullRoleMcp 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, containerRegistryName, 'mcp-acrpull')
  scope: existingRegistry
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: mcpPrincipalId
    principalType: 'ServicePrincipal'
  }
}
