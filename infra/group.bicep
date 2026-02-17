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

// ---------------------------------------------------------------------------
// Naming Convention
// ---------------------------------------------------------------------------
module naming 'modules/naming.bicep' = {
  name: 'naming'
  params: {
    appName: appName
    location: location
    suffix: suffix
  }
}

// ---------------------------------------------------------------------------
// Azure SQL — uses MCP Container App managed identity as AD admin
// Deployed after Container Apps so we can reference its principal ID
// ---------------------------------------------------------------------------
module sql 'modules/sql.bicep' = {
  name: 'sql'
  params: {
    sqlServerName: naming.outputs.sqlServerName
    sqlDatabaseName: naming.outputs.sqlDatabaseName
    location: location
    azureADAdminObjectId: sqlAdminObjectId
    azureADAdminLogin: sqlAdminLogin
    mcpPrincipalId: containerApps.outputs.mcpPrincipalId
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
    apiPrincipalId: containerApps.outputs.apiPrincipalId
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
// Container Apps (API + MCP)
// ---------------------------------------------------------------------------
module containerApps 'modules/container-apps.bicep' = {
  name: 'containerApps'
  params: {
    containerAppEnvironmentName: naming.outputs.containerAppEnvironmentName
    containerAppApiName: naming.outputs.containerAppApiName
    containerAppMcpName: naming.outputs.containerAppMcpName
    location: location
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
    apiPrincipalId: containerApps.outputs.apiPrincipalId
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
