// ============================================================================
// Cross-Region Resources Module
// Deploys resources that require a region different from the resource group
// Called by main.bicep alongside group.bicep
// ============================================================================

@description('Application name used in resource naming')
param appName string

@description('Environment suffix')
@minLength(3)
param suffix string

@description('Publisher organization name used in naming')
param apimPublisherName string

@description('Location for cross-region resources')
param resourceLocation string

// ---------------------------------------------------------------------------
// Naming Convention
// ---------------------------------------------------------------------------
module naming 'modules/naming.bicep' = {
  name: 'cross-region-naming'
  params: {
    appName: appName
    location: resourceLocation
    suffix: suffix
    apimPublisherName: apimPublisherName
  }
}

// ---------------------------------------------------------------------------
// API Center
// ---------------------------------------------------------------------------
module apiCenter 'modules/api-center.bicep' = {
  name: 'apiCenter'
  params: {
    apiCenterName: naming.outputs.apiCenterName
    location: resourceLocation
  }
}
