// ============================================================================
// Azure Static Web App Module
// Creates a Static Web App for hosting the frontend
// ============================================================================

@description('Name of the Static Web App')
param staticWebAppName string

@description('Azure region for deployment')
param location string

// ---------------------------------------------------------------------------
// Static Web App
// ---------------------------------------------------------------------------
resource staticWebApp 'Microsoft.Web/staticSites@2025-03-01' = {
  name: staticWebAppName
  location: location
  tags: {
    SecurityControl: 'Ignore'
  }
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {}
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
output staticWebAppId string = staticWebApp.id
output defaultHostname string = staticWebApp.properties.defaultHostname
