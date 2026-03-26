// ============================================================================
// Azure API Center Module
// Creates an API Center instance
// ============================================================================

@description('Name of the API Center instance')
param apiCenterName string

@description('Azure region for deployment')
param location string

resource apiCenter 'Microsoft.ApiCenter/services@2024-03-01' = {
  name: apiCenterName
  location: location
  tags: {
    SecurityControl: 'Ignore'
  }
}

output apiCenterName string = apiCenter.name
