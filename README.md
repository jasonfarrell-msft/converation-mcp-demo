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

> **Note:** After deploying, verify that the new revision reaches a **Running** state in the Container App. You can check this in the Azure Portal under the Container App's **Revisions** blade, or by running:
>
> ```bash
> az containerapp revision list \
>   --name <your-container-app-name> \
>   --resource-group <your-resource-group> \
>   --output table
> ```

## 5. Deploy MCP Server

The [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) is an open standard that allows LLMs to interact with external tools and data sources. In this project, the MCP server acts as a bridge between the Foundry agent and the SQL database. When a user asks a question, the LLM generates a SQL query and invokes the MCP server to execute it against the database. The results are returned to the agent, which uses them to ground its response — forming a retrieval-augmented generation (RAG) workflow.

### Build the Container Image

From the root of the repository, build the MCP server Docker image and push it to Azure Container Registry:

```bash
az acr build \
  --registry <your-acr-name> \
  --image survey-data-mcp:v1 \
  ./Farrellsoft.Example.SurveyDataMcp
```

Replace `<your-acr-name>` with the Azure Container Registry name from the `az deployment` command output in Step 1.

### Register the Container Registry with Container Apps

The Bicep deployment does not configure ACR on the Container Apps (they start with a placeholder image). Register your ACR with the MCP Container App so it can pull images using its system-assigned managed identity:

```bash
az containerapp registry set \
  --name <your-mcp-container-app-name> \
  --resource-group <your-resource-group> \
  --server <your-acr-name>.azurecr.io \
  --identity system
```

### Grant SQL Server Access to the Managed Identity

The MCP Container App uses its system-assigned managed identity to authenticate with SQL Server. Assign the managed identity the appropriate Azure RBAC role to allow it to read data from the database.

1. Get the principal ID of the MCP Container App's system-assigned managed identity:

```bash
az containerapp show \
  --name <your-mcp-container-app-name> \
  --resource-group <your-resource-group> \
  --query "identity.principalId" \
  --output tsv
```

2. Get the resource ID of the SQL Server:

```bash
az sql server show \
  --name <your-sql-server> \
  --resource-group <your-resource-group> \
  --query "id" \
  --output tsv
```

3. Assign the **SQL Server Contributor** role to the managed identity, scoped to the SQL Server:

```bash
az role assignment create \
  --assignee <principal-id> \
  --role "SQL Server Contributor" \
  --scope <sql-server-resource-id>
```

Replace `<principal-id>` with the output from step 1 and `<sql-server-resource-id>` with the output from step 2.

### Deploy to Azure Container Apps

Deploy a new revision of the MCP Container App using the newly built image:

```bash
az containerapp update \
  --name <your-mcp-container-app-name> \
  --resource-group <your-resource-group> \
  --image <your-acr-name>.azurecr.io/survey-data-mcp:v1 \
  --min-replicas 1 \
  --max-replicas 3 \
  --set-env-vars \
    "SqlServer=<your-sql-server>.database.windows.net" \
    "SqlDatabase=<your-database-name>"
```

| Environment Variable | Description |
|---|---|
| `SqlServer` | The fully qualified hostname of the SQL Server instance. |
| `SqlDatabase` | The name of the database containing the survey data. |

> **Note:** After deploying, verify that the new revision reaches a **Running** state in the Container App. You can check this in the Azure Portal under the Container App's **Revisions** blade, or by running:
>
> ```bash
> az containerapp revision list \
>   --name <your-mcp-container-app-name> \
>   --resource-group <your-resource-group> \
>   --output table
> ```

## 6. Configure Agent to Use MCP Server

Now that the MCP server is deployed and running, connect it to the Foundry agent so the agent can execute SQL queries against the survey database.

1. Navigate to the [Azure AI Foundry](https://ai.azure.com) portal and open the agent created in Step 2.
2. In the agent configuration, scroll to the **Tools** section.
3. Click **Add tool** and select **MCP Server** as the tool type.
4. Configure the MCP server connection:
   - **Endpoint URL** — Enter the FQDN of the MCP Container App followed by `/sse` (e.g., `https://<your-mcp-container-app-fqdn>/sse`).
5. Click **Save** to save the agent configuration.

You can find the MCP Container App's FQDN by running:

```bash
az containerapp show \
  --name <your-mcp-container-app-name> \
  --resource-group <your-resource-group> \
  --query "properties.configuration.ingress.fqdn" \
  --output tsv
```
