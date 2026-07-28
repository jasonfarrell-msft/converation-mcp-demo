// ============================================================================
// Azure App Service Module
// Creates an App Service Plan (Standard S1) and a Web App for hosting the
// static frontend. HTTPS-only; TLS 1.2 minimum.
// ============================================================================

@description('Name of the App Service Plan')
param appServicePlanName string

@description('Name of the Web App')
param webAppName string

@description('Azure region for deployment')
param location string

@description('API endpoint URL injected as an app setting for reference')
param apiUrl string

// ---------------------------------------------------------------------------
// App Service Plan — Standard S1 (Windows)
// ---------------------------------------------------------------------------
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  tags: {
    SecurityControl: 'Ignore'
  }
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
  properties: {}
}

// ---------------------------------------------------------------------------
// Web App — serves the static frontend via IIS
// ---------------------------------------------------------------------------
resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  tags: {
    SecurityControl: 'Ignore'
  }
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      http20Enabled: true
      minTlsVersion: '1.2'
      // Store the backend API URL as an app setting for operational visibility.
      // The static app.js has the URL baked in; this setting is for reference/ops.
      appSettings: [
        {
          name: 'API_URL'
          value: apiUrl
        }
      ]
    }
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
output webAppId string = webApp.id
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
