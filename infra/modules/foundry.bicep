// ============================================================================
// Microsoft Foundry Module
// Creates AI Services (Cognitive Services) account, Foundry project,
// and a GPT 5.2 model deployment
// ============================================================================

@description('Name of the Foundry (AI Services) account')
param foundryAccountName string

@description('Azure region for deployment')
param location string

@description('Name for the GPT model deployment')
param modelDeploymentName string

// ---------------------------------------------------------------------------
// AI Services Account (Microsoft Foundry)
// ---------------------------------------------------------------------------
resource aiServicesAccount 'Microsoft.CognitiveServices/accounts@2025-09-01' = {
  name: foundryAccountName
  location: location
  tags: {
    SecurityControl: 'Ignore'
  }
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: foundryAccountName
    publicNetworkAccess: 'Enabled'
    allowProjectManagement: true
  }
}

// ---------------------------------------------------------------------------
// Foundry Project
// ---------------------------------------------------------------------------
resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-09-01' = {
  parent: aiServicesAccount
  name: '${foundryAccountName}-project'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: '${foundryAccountName} Project'
    description: 'AI Foundry project for ${foundryAccountName}'
  }
}

// ---------------------------------------------------------------------------
// GPT 5.2 Chat Model Deployment
// ---------------------------------------------------------------------------
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-09-01' = {
  parent: aiServicesAccount
  name: modelDeploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-5.2'
      version: '2025-12-11'
    }
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
output aiServicesAccountId string = aiServicesAccount.id
output aiServicesEndpoint string = aiServicesAccount.properties.endpoint
output projectId string = foundryProject.id
output modelDeploymentId string = modelDeployment.id
