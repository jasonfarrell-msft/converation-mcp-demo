// Parameters
@description('Name of the Azure AI Foundry instance')
param instanceName string

@description('Name of the Azure AI Foundry project')
param projectName string

@description('URL of the MCP Container App')
param mcpUrl string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {
  environment: 'production'
  application: 'surveydata'
}

// Azure AI Foundry Instance (CognitiveServices Account)
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: instanceName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: instanceName
    publicNetworkAccess: 'Enabled'
  }
}

// Azure AI Foundry Project
resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: aiFoundry
  name: projectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: 'Azure AI Foundry Project for Survey Data Application'
  }
}

// MCP Connection
resource mcpConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01' = {
  parent: aiProject
  name: 'survey-data-mcp'
  properties: {
    authType: 'None'
    category: 'RemoteTool'
    target: mcpUrl
    useWorkspaceManagedIdentity: false
    isSharedToAll: false
    sharedUserList: []
    peRequirement: 'NotRequired'
    peStatus: 'NotApplicable'
    metadata: {
      type: 'custom_MCP'
    }
  }
}

// Outputs
output instanceId string = aiFoundry.id
output instanceName string = aiFoundry.name
output projectId string = aiProject.id
output projectName string = aiProject.name
output mcpConnectionId string = mcpConnection.id
output mcpConnectionName string = mcpConnection.name

