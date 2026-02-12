# Conversational MCP Demo

## Prerequisites

- Access to an Azure tenant with **Contributor** (or similar) role
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), logged in as a valid user in the target tenant

## Setup Azure Components

From within the `infra/` folder, run the following command:

```bash
az deployment sub create \
  --template-file main.bicep --location eastus2 \
  --parameters main.bicepparam
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `appName` | `string` | Application name used in resource naming. |
| `location` | `string` | Azure region for deployment. Allowed values: `eastus2`, `westus`, `southcentralus`. |
| `suffix` | `string` | Environment suffix (minimum 3 characters). Used alongside `appName` and `location` to generate unique resource names. |
| `modelDeploymentName` | `string` | Name for the GPT model deployment in Foundry. |
| `sqlAdminObjectId` | `string` | Object ID of the Azure AD user or group to be assigned as the SQL admin. |
| `sqlAdminLogin` | `string` | Login (email) of the Azure AD SQL admin. |
