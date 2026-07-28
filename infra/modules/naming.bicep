// ============================================================================
// Naming Convention Module
// Generates resource names following organizational naming standards
//
// Dash-allowed resources:  <abbreviation>-<appName>-<regionalSuffix>
// No-dash resources:       <abbreviation><appName><regionalSuffix>
// ============================================================================

@description('Application name used in resource naming')
param appName string

@description('Azure region for deployment')
@allowed([
  'eastus'
  'eastus2'
  'westus'
  'southcentralus'
  'swedencentral'
])
param location string

@description('Environment suffix')
@minLength(3)
param suffix string

// ---------------------------------------------------------------------------
// Location short code mapping
// ---------------------------------------------------------------------------
var locationShortCodes = {
  eastus: 'eus'
  eastus2: 'eus2'
  westus: 'wus'
  southcentralus: 'sus'
  swedencentral: 'swc'
}

var shortLocation = locationShortCodes[location]
var regionalSuffix = startsWith(toLower(suffix), shortLocation) ? toLower(suffix) : '${shortLocation}-${toLower(suffix)}'

// ---------------------------------------------------------------------------
// Resources that allow dashes
// Pattern: <abbreviation>-<appName>-<regionalSuffix>
// ---------------------------------------------------------------------------
output resourceGroupName string = 'rg-${appName}-${regionalSuffix}'
output sqlServerName string = 'sqlsvr-${appName}-${regionalSuffix}'
output sqlDatabaseName string = 'sqldb-${appName}-${regionalSuffix}'
output containerAppEnvironmentName string = 'cae-${appName}-${regionalSuffix}'
output containerAppApiName string = 'aca-${appName}-api-${regionalSuffix}'
output containerAppMcpName string = 'aca-${appName}-mcp-${regionalSuffix}'
output foundryAccountName string = 'foundry-${appName}-${regionalSuffix}'
output apimName string = 'apim-${appName}-${regionalSuffix}'
output apiCenterName string = 'apic-${appName}-${regionalSuffix}'
output userAssignedIdentityName string = 'uai-${appName}-${regionalSuffix}'
output appServicePlanName string = 'asp-${appName}-${regionalSuffix}'
output webAppName string = 'app-${appName}-${regionalSuffix}'

// ---------------------------------------------------------------------------
// Resources that do NOT allow dashes
// Pattern: <abbreviation><appName><regionalSuffix>
// Max length rules enforced via substring truncation
// ---------------------------------------------------------------------------

// Storage Account: max 24 characters, lowercase alphanumeric only
var storageRawName = toLower('st${appName}${regionalSuffix}')
output storageAccountName string = length(storageRawName) > 24
  ? substring(storageRawName, 0, 24)
  : storageRawName

// Container Registry: max 50 characters, alphanumeric only
var crRawName = 'cr${appName}${regionalSuffix}'
output containerRegistryName string = length(crRawName) > 50
  ? substring(crRawName, 0, 50)
  : crRawName
