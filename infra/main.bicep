// ============================================================================
// Main Deployment
// Subscription-scoped: creates the resource group, then deploys all
// resources into it via the group.bicep module
// ============================================================================
targetScope = 'subscription'

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
// Naming - derive resource group name inline (subscription scope cannot
// call resource-group-scoped modules)
// ---------------------------------------------------------------------------
var locationShortCodes = {
  eastus2: 'eus2'
  westus: 'wus'
  southcentralus: 'sus'
}
var shortLocation = locationShortCodes[location]
var resourceGroupName = 'rg-${appName}-${shortLocation}-${suffix}'

// ---------------------------------------------------------------------------
// Resource Group
// ---------------------------------------------------------------------------
resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    SecurityControl: 'Ignore'
  }
}

// ---------------------------------------------------------------------------
// Deploy all resources into the resource group
// ---------------------------------------------------------------------------
module group 'group.bicep' = {
  name: 'group-deployment'
  scope: resourceGroup
  params: {
    appName: appName
    location: location
    suffix: suffix
    modelDeploymentName: modelDeploymentName
    sqlAdminObjectId: sqlAdminObjectId
    sqlAdminLogin: sqlAdminLogin
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
output resourceGroupName string = resourceGroup.name
output sqlServerFqdn string = group.outputs.sqlServerFqdn
output storageAccountName string = group.outputs.storageAccountName
output aiServicesEndpoint string = group.outputs.aiServicesEndpoint
output containerRegistryLoginServer string = group.outputs.containerRegistryLoginServer
output apiAppFqdn string = group.outputs.apiAppFqdn
output mcpAppFqdn string = group.outputs.mcpAppFqdn
output staticWebAppHostname string = group.outputs.staticWebAppHostname
