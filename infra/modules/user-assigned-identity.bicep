// ============================================================================
// User-Assigned Managed Identity Module
// Creates a UAI for shared use across Container Apps (e.g., ACR pull)
// ============================================================================

@description('Name of the User-Assigned Managed Identity')
param userAssignedIdentityName string

@description('Azure region for deployment')
param location string

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: userAssignedIdentityName
  location: location
  tags: {
    SecurityControl: 'Ignore'
  }
}

output userAssignedIdentityId string = userAssignedIdentity.id
output userAssignedIdentityPrincipalId string = userAssignedIdentity.properties.principalId
output userAssignedIdentityClientId string = userAssignedIdentity.properties.clientId
