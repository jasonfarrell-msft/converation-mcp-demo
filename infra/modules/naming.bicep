// ============================================================================
// Naming Convention Module
// Generates resource names following organizational naming standards
//
// Dash-allowed resources:  <abbreviation>-<appName>-<shortLocation>-<suffix>
// No-dash resources:       <abbreviation><appName><shortLocation><suffix>
// ============================================================================

@description('Application name used in resource naming')
param appName string

@description('Azure region for deployment')
@allowed([
  'eastus'
  'eastus2'
  'westus'
  'southcentralus'
])
param location string

@description('Environment suffix')
@minLength(3)
param suffix string

@description('Publisher organization name used for APIM naming')
param apimPublisherName string

// ---------------------------------------------------------------------------
// Location short code mapping
// ---------------------------------------------------------------------------
var locationShortCodes = {
  eastus: 'eus'
  eastus2: 'eus2'
  westus: 'wus'
  southcentralus: 'sus'
}

var shortLocation = locationShortCodes[location]

// ---------------------------------------------------------------------------
// Resources that allow dashes
// Pattern: <abbreviation>-<appName>-<shortLocation>-<suffix>
// ---------------------------------------------------------------------------
output resourceGroupName string = 'rg-${appName}-${shortLocation}-${suffix}'
output sqlServerName string = 'sqlsvr-${appName}-${shortLocation}-${suffix}'
output sqlDatabaseName string = 'sqldb-${appName}-${shortLocation}-${suffix}'
output containerAppEnvironmentName string = 'cae-${appName}-${shortLocation}-${suffix}'
output containerAppApiName string = 'aca-${appName}-api-${shortLocation}-${suffix}'
output containerAppMcpName string = 'aca-${appName}-mcp-${shortLocation}-${suffix}'
output foundryAccountName string = 'foundry-${appName}-${shortLocation}-${suffix}'
output apimName string = 'apim-${apimPublisherName}-${shortLocation}-${suffix}'
output apiCenterName string = 'apic-${apimPublisherName}-${shortLocation}-${suffix}'
output userAssignedIdentityName string = 'uai-${appName}-${shortLocation}-${suffix}'

// ---------------------------------------------------------------------------
// Resources that do NOT allow dashes
// Pattern: <abbreviation><appName><shortLocation><suffix>
// Max length rules enforced via substring truncation
// ---------------------------------------------------------------------------

// Storage Account: max 24 characters, lowercase alphanumeric only
var storageRawName = toLower('st${appName}${shortLocation}${suffix}')
output storageAccountName string = length(storageRawName) > 24
  ? substring(storageRawName, 0, 24)
  : storageRawName

// Container Registry: max 50 characters, alphanumeric only
var crRawName = 'cr${appName}${shortLocation}${suffix}'
output containerRegistryName string = length(crRawName) > 50
  ? substring(crRawName, 0, 50)
  : crRawName
