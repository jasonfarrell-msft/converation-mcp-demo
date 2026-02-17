// ============================================================================
// Azure SQL Module
// Creates SQL Server with Azure AD-only auth, database, and firewall rule
// ============================================================================

@description('Name of the SQL Server')
param sqlServerName string

@description('Name of the SQL Database')
param sqlDatabaseName string

@description('Azure region for deployment')
param location string

@description('Object ID of the Azure AD admin user')
param azureADAdminObjectId string

@description('Login name (email) for the Azure AD admin user')
param azureADAdminLogin string

@description('Principal ID of the MCP Container App managed identity for data access')
param mcpPrincipalId string

// ---------------------------------------------------------------------------
// SQL Server — Azure AD-only authentication (required by policy)
// ---------------------------------------------------------------------------
resource sqlServer 'Microsoft.Sql/servers@2023-08-01' = {
  name: sqlServerName
  location: location
  tags: {
    SecurityControl: 'Ignore'
  }
  properties: {
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: azureADAdminLogin
      sid: azureADAdminObjectId
      principalType: 'User'
      tenantId: subscription().tenantId
    }
  }
}

// ---------------------------------------------------------------------------
// SQL Database
// ---------------------------------------------------------------------------
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: {
    SecurityControl: 'Ignore'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
  }
}

// ---------------------------------------------------------------------------
// Firewall: Allow Azure services
// ---------------------------------------------------------------------------
resource firewallRule 'Microsoft.Sql/servers/firewallRules@2023-08-01' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource firewallRuleAllowAll 'Microsoft.Sql/servers/firewallRules@2023-08-01' = {
  parent: sqlServer
  name: 'AllowAllPublicConnections'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

// ---------------------------------------------------------------------------
// SQL DB Contributor role for MCP Container App
// Grants the MCP managed identity read/write data access
// ---------------------------------------------------------------------------
var sqlDbContributorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '9b7fa17d-e63e-47b0-bb0a-15c516ac86ec'
)

resource sqlRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sqlDatabase.id, mcpPrincipalId, '9b7fa17d-e63e-47b0-bb0a-15c516ac86ec')
  scope: sqlServer
  properties: {
    roleDefinitionId: sqlDbContributorRoleId
    principalId: mcpPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
output sqlServerId string = sqlServer.id
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseId string = sqlDatabase.id
