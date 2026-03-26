// ============================================================================
// Resource Group Module
// Orchestrates all Azure resource deployments within the resource group
// Called by main.bicep after resource group creation
// ============================================================================

@description('Application name used in resource naming')
param appName string

@description('Azure region for deployment')
@allowed([
  'eastus2'
  'westus'
  'southcentralus'
])
param location string

@description('Environment suffix')
@minLength(3)
param suffix string

@description('Name for the GPT model deployment in Foundry')
param modelDeploymentName string

@description('Object ID of the Azure AD SQL admin')
param sqlAdminObjectId string

@description('Login (email) of the Azure AD SQL admin')
param sqlAdminLogin string

@description('Publisher email for API Management')
param apimPublisherEmail string

@description('Publisher organization name for API Management')
param apimPublisherName string

@description('Container image for the API app')
param apiImageName string

@description('Container image for the MCP app')
param mcpImageName string

@description('Agent name for the API app')
param agentName string

// ---------------------------------------------------------------------------
// Naming Convention
// ---------------------------------------------------------------------------
module naming 'modules/naming.bicep' = {
  name: 'naming'
  params: {
    appName: appName
    location: location
    suffix: suffix
    apimPublisherName: apimPublisherName
  }
}

// ---------------------------------------------------------------------------
// Azure SQL
// ---------------------------------------------------------------------------
module sql 'modules/sql.bicep' = {
  name: 'sql'
  params: {
    sqlServerName: naming.outputs.sqlServerName
    sqlDatabaseName: naming.outputs.sqlDatabaseName
    location: location
    azureADAdminObjectId: sqlAdminObjectId
    azureADAdminLogin: sqlAdminLogin
  }
}

// ---------------------------------------------------------------------------
// Storage Account
// ---------------------------------------------------------------------------
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    storageAccountName: naming.outputs.storageAccountName
    location: location
  }
}

// ---------------------------------------------------------------------------
// Microsoft Foundry (AI Services + Project + Model Deployment)
// ---------------------------------------------------------------------------
module foundry 'modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    foundryAccountName: naming.outputs.foundryAccountName
    location: location
    modelDeploymentName: modelDeploymentName
  }
}

// ---------------------------------------------------------------------------
// Container Registry
// ---------------------------------------------------------------------------
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistry'
  params: {
    containerRegistryName: naming.outputs.containerRegistryName
    location: location
  }
}

// ---------------------------------------------------------------------------
// User-Assigned Managed Identity (shared for ACR pull)
// ---------------------------------------------------------------------------
module userAssignedIdentity 'modules/user-assigned-identity.bicep' = {
  name: 'userAssignedIdentity'
  params: {
    userAssignedIdentityName: naming.outputs.userAssignedIdentityName
    location: location
  }
}

// ---------------------------------------------------------------------------
// Container Apps (API + MCP)
// ---------------------------------------------------------------------------
module containerApps 'modules/container-apps.bicep' = {
  name: 'containerApps'
  params: {
    containerAppEnvironmentName: naming.outputs.containerAppEnvironmentName
    containerAppApiName: naming.outputs.containerAppApiName
    containerAppMcpName: naming.outputs.containerAppMcpName
    location: location
    apiImageName: apiImageName
    mcpImageName: mcpImageName
    userAssignedIdentityId: userAssignedIdentity.outputs.userAssignedIdentityId
    containerRegistryServer: containerRegistry.outputs.loginServer
    foundryProjectEndpoint: foundry.outputs.foundryProjectEndpoint
    agentName: agentName
    sqlServerFqdn: sql.outputs.sqlServerFqdn
    sqlDatabaseName: sql.outputs.sqlDatabaseName
  }
}

// ---------------------------------------------------------------------------
// API Management
// ---------------------------------------------------------------------------
module apim 'modules/apim.bicep' = {
  name: 'apim'
  params: {
    apimName: naming.outputs.apimName
    location: location
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
  }
}

// ---------------------------------------------------------------------------
// AcrPull Role Assignments
// Grants the Container App managed identities pull access to ACR
// ---------------------------------------------------------------------------
module acrRoleAssignments 'modules/acr-role-assignments.bicep' = {
  name: 'acrRoleAssignments'
  params: {
    containerRegistryName: naming.outputs.containerRegistryName
    uaiPrincipalId: userAssignedIdentity.outputs.userAssignedIdentityPrincipalId
  }
}

// ---------------------------------------------------------------------------
// Foundry Role Assignments
// Grants Azure AI User role to the API Container App system-assigned identity
// ---------------------------------------------------------------------------
module foundryRoleAssignments 'modules/foundry-role-assignments.bicep' = {
  name: 'foundryRoleAssignments'
  params: {
    aiServicesAccountName: foundry.outputs.aiServicesAccountName
    apiPrincipalId: containerApps.outputs.apiPrincipalId
  }
}

// ---------------------------------------------------------------------------
// SQL Role Assignments
// Grants SQL DB Contributor role to the MCP Container App system-assigned identity
// ---------------------------------------------------------------------------
module sqlRoleAssignments 'modules/sql-role-assignments.bicep' = {
  name: 'sqlRoleAssignments'
  params: {
    sqlServerName: sql.outputs.sqlServerName
    mcpPrincipalId: containerApps.outputs.mcpPrincipalId
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
output sqlServerFqdn string = sql.outputs.sqlServerFqdn
output storageAccountName string = storage.outputs.storageAccountName
output aiServicesEndpoint string = foundry.outputs.aiServicesEndpoint
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output apiAppFqdn string = containerApps.outputs.apiAppFqdn
output mcpAppFqdn string = containerApps.outputs.mcpAppFqdn
output apimGatewayUrl string = apim.outputs.apimGatewayUrl
