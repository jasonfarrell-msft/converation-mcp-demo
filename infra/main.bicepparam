// ============================================================================
// Bicep Parameters File
// Provide values for deployment
// ============================================================================
using 'main.bicep'

param appName = 'surveychat'
param location = 'swedencentral'
param suffix = 'swc01'
param resourceGroupName = 'rg-survey-chat-swc01'
param modelDeploymentName = 'gpt-52-deployment'
param sqlAdminObjectId = 'd6c719d1-7920-4444-912d-8f03ae23e3d0'
param sqlAdminLogin = 'jasonfarrell_microsoft.com#EXT#@MngEnvMCAP852125.onmicrosoft.com'
param apimPublisherEmail = 'jasonfarrell@microsoft.com'
param apimPublisherName = 'farrellsoft'
param apiImageName = 'crsurveychatswc01.azurecr.io/survey-data-api:v1'
param mcpImageName = 'crsurveychatswc01.azurecr.io/survey-data-mcp:v1'
param agentName = 'surveychat-agent'
param resourceLocation = 'swedencentral'
