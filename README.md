# Conversational MCP Demo

## Prerequisites

- Access to an Azure tenant with **Contributor** (or similar) role
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), logged in as a valid user in the target tenant
- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)

## 1. Setup Azure Components

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

## 2. Setup Foundry Agent

Create an agent in the Azure AI Foundry portal that will be used by the API.

1. Navigate to the [Azure AI Foundry](https://ai.azure.com) portal.
2. Open the Foundry project that was created during the deployment in Step 1.
3. In the top navigation bar, select **Build**.
4. Select **Agents**.
5. Click **+ New agent** to create a new agent.
6. Give the agent a name of your choice and complete the setup.

> **Important:** Take note of the agent name you chose — you will need it when configuring the API in a later step.

## 3. Load Survey Data into SQL Server

From within the `Farrellsoft.Example.SurveyDataLoad/` folder, follow the steps below.

### Set Environment Variables

The data load project connects to SQL Server using the Azure CLI logged-in user (Entra ID authentication). Set the following environment variables using the values from the `az deployment` command output in Step 1:

```bash
export AZURE_SQL_SERVER="<your-sql-server>.database.windows.net"
export AZURE_SQL_DATABASE="<your-database-name>"
```

Ensure you are logged in to the Azure CLI as the user configured as the SQL admin:

```bash
az login
```

### Install Dependencies

Restore NuGet packages and install the Entity Framework CLI tool:

```bash
dotnet restore
dotnet tool install --global dotnet-ef
```

> **Note:** You may need to reload your shell or run `export PATH="$HOME/.dotnet/tools:$PATH"` to make the `dotnet-ef` tool available on the command line.

### Apply Database Migrations

Run Entity Framework migrations to create the required schema:

```bash
dotnet ef database update
```

### Run the Data Load

Execute the console application to load data from `survey_data.csv` into the database:

```bash
dotnet run
```

### Verify the Data

It is recommended that you use a query tool of your choice (e.g., Azure Data Studio, SQL Server Management Studio, or the Azure Portal query editor) to verify the data has been loaded into the database successfully.

## 4. Setup API

### Build the Container Image

From the root of the repository, build the API Docker image and push it to Azure Container Registry:

```bash
az acr build \
  --registry <your-acr-name> \
  --image survey-data-api:v1 \
  ./Farrellsoft.Example.SurveyDataApi
```

Replace `<your-acr-name>` with the Azure Container Registry name from the `az deployment` command output in Step 1.

### Deploy to Azure Container Apps

Deploy a new revision of the Container App using the newly built image:

```bash
az containerapp update \
  --name <your-container-app-name> \
  --resource-group <your-resource-group> \
  --image <your-acr-name>.azurecr.io/survey-data-api:v1 \
  --set-env-vars \
    "Key=<your-foundry-project-key>" \
    "FoundryEndpoint=<your-foundry-project-uri>" \
    "DeploymentName=<your-chat-model-deployment-name>" \
    "AgentName=<your-agent-name>"
```

| Environment Variable | Description |
|---|---|
| `Key` | The Foundry project key (to be confirmed). |
| `FoundryEndpoint` | The URI to the Foundry project. |
| `DeploymentName` | The name of the deployed chat model (provided as output from the Bicep deployment in Step 1). |
| `AgentName` | The name of the agent to target. |
