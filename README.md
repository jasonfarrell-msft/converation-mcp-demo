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

> **Note:** The new [Foundry](https://learn.microsoft.com/azure/ai-foundry/) experience must be enabled in the target tenant before proceeding.

Create an agent in the Azure AI Foundry portal that will be used by the API.

1. Navigate to the [Azure AI Foundry](https://ai.azure.com) portal.
2. Open the Foundry project that was created during the deployment in Step 1.
3. In the top navigation bar, select **Build**.
4. Select **Agents**.
5. Click **Create agent** to create a new agent.
6. Give the agent a name of your choice and complete the setup.

> **Important:** Take note of the agent name you chose — you will need it when configuring the API in a later step.

### Configure the Agent

1. **Model** — Select the `gpt-5.2` model that was deployed as part of the infrastructure script in Step 1. The deployment name will match the `modelDeploymentName` parameter value you provided.
2. **Instructions** — Copy the contents of [Farrellsoft.Example.SurveyDataApi/support/system.md](Farrellsoft.Example.SurveyDataApi/support/system.md) and paste it into the agent's Instructions field.
3. Click **Save** to save the agent.

For a deeper look at the prompt design and how it drives agent behavior, see [Understanding the prompt](doc.md#understanding-the-prompt).

## 3. Load Survey Data into SQL Server

From within the `Farrellsoft.Example.SurveyDataLoad/` folder, follow the steps below.

### Prerequisites

Ensure you are logged in to the Azure CLI as the user configured as the SQL admin (Entra ID authentication is used):

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

Run Entity Framework migrations to create the required schema. Pass the SQL Server host and database name using `--server` and `--database` after `--`:

```bash
dotnet ef database update -- \
  --server <your-sql-server>.database.windows.net \
  --database <your-database-name>
```

### Run the Data Load

Execute the console application to load data from `survey_data.csv` into the database. Pass the same `--server` and `--database` arguments:

```bash
dotnet run -- \
  --server <your-sql-server>.database.windows.net \
  --database <your-database-name>
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

### Register the Container Registry with Container Apps

The Bicep deployment does not configure ACR on the Container Apps (they start with a placeholder image). Register your ACR with each Container App so they can pull images using their system-assigned managed identities:

```bash
az containerapp registry set \
  --name <your-container-app-name> \
  --resource-group <your-resource-group> \
  --server <your-acr-name>.azurecr.io \
  --identity system
```

Run this command for **both** the API and MCP Container Apps.

### Store the Foundry Key as a Secret

Add the Foundry project key as a secret in the Container App:

```bash
az containerapp secret set \
  --name <your-container-app-name> \
  --resource-group <your-resource-group> \
  --secrets foundry-key=<your-foundry-project-key>
```

### Deploy to Azure Container Apps

Deploy a new revision of the Container App using the newly built image:

```bash
az containerapp update \
  --name <your-container-app-name> \
  --resource-group <your-resource-group> \
  --image <your-acr-name>.azurecr.io/survey-data-api:v1 \
  --min-replicas 1 \
  --max-replicas 3 \
  --set-env-vars \
    "Key=secretref:foundry-key" \
    "FoundryEndpoint=<your-foundry-project-uri>" \
    "DeploymentName=<your-chat-model-deployment-name>" \
    "AgentName=<your-agent-name>"
```

| Environment Variable | Description |
|---|---|
| `Key` | Reference to the `foundry-key` secret stored in the Container App. |
| `FoundryEndpoint` | The URI to the Foundry project. |
| `DeploymentName` | The name of the deployed chat model (provided as output from the Bicep deployment in Step 1). |
| `AgentName` | The name of the agent to target. |
