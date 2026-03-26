// ============================================================================
// Foundry Role Assignments Module
// Grants Azure AI User role to the API Container App system-assigned identity
// ============================================================================

@description('Name of the AI Services account')
param aiServicesAccountName string

@description('Principal ID of the API Container App system-assigned identity')
param apiPrincipalId string

// ---------------------------------------------------------------------------
// Reference the existing AI Services account
// ---------------------------------------------------------------------------
resource existingAiServices 'Microsoft.CognitiveServices/accounts@2025-09-01' existing = {
  name: aiServicesAccountName
}

// Azure AI User built-in role definition ID
var azureAIUserRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '53ca6127-db72-4b80-b1b0-d745d6d5456d'
)

// ---------------------------------------------------------------------------
// Azure AI User for API Container App
// ---------------------------------------------------------------------------
resource apiOpenAIUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aiServicesAccountName, 'api-openai-user')
  scope: existingAiServices
  properties: {
    roleDefinitionId: azureAIUserRoleId
    principalId: apiPrincipalId
    principalType: 'ServicePrincipal'
  }
}
