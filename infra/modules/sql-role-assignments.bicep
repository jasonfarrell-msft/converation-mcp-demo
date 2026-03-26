// ============================================================================
// SQL Role Assignments Module
// Grants SQL DB Contributor role to the MCP Container App system-assigned identity
// ============================================================================

@description('Name of the SQL Server')
param sqlServerName string

@description('Principal ID of the MCP Container App system-assigned identity')
param mcpPrincipalId string

// ---------------------------------------------------------------------------
// Reference the existing SQL Server
// ---------------------------------------------------------------------------
resource existingSqlServer 'Microsoft.Sql/servers@2023-08-01' existing = {
  name: sqlServerName
}

// SQL DB Contributor built-in role definition ID
var sqlDbContributorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '9b7fa17d-e63e-47b0-bb0a-15c516ac86ec'
)

// ---------------------------------------------------------------------------
// SQL DB Contributor for MCP Container App
// ---------------------------------------------------------------------------
resource sqlRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, sqlServerName, mcpPrincipalId, '9b7fa17d-e63e-47b0-bb0a-15c516ac86ec')
  scope: existingSqlServer
  properties: {
    roleDefinitionId: sqlDbContributorRoleId
    principalId: mcpPrincipalId
    principalType: 'ServicePrincipal'
  }
}
