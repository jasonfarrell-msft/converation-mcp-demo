# Conversational MCP Demo

## Prerequisites

- Access to an Azure tenant with **Contributor** (or similar) role
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), logged in as a valid user in the target tenant
- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- The **Object ID** and **email address** of a Microsoft Entra user who will serve as the SQL Server administrator. You can find the Object ID in the Azure Portal under **Microsoft Entra ID > Users > [user] > Properties**, or by running:
  ```bash
  az ad user show --id <user-email> --query id --output tsv
  ```

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

Ensure you are logged in to the Azure CLI as a user with access to the SQL database (e.g., the SQL admin or a user with `db_owner` / `db_datawriter` permissions):

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
    "AgentName=<your-agent-name>"
```

| Environment Variable | Description |
|---|---|
| `Key` | Reference to the `foundry-key` secret stored in the Container App. |
| `FoundryEndpoint` | The URI to the Foundry project. |
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

### Grant SQL Database Access to the Managed Identity

The MCP Container App uses its system-assigned managed identity to authenticate with SQL Server via Microsoft Entra. You must create a database user for this identity and grant it read access.

1. Open the [Azure Portal](https://portal.azure.com) and navigate to your SQL Database (`<your-database-name>`).
2. In the left menu, select **Query editor**.
3. Log in as the SQL admin (the Entra user configured during deployment).
4. Run the following SQL to create a contained database user for the MCP Container App's managed identity and grant it read access:

```sql
CREATE USER [<your-mcp-container-app-name>] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [<your-mcp-container-app-name>];
```

Replace `<your-mcp-container-app-name>` with the name of the MCP Container App created by the Bicep deployment (e.g., `aca-surveychat-mcp-eus2-yx02`).

> **Important:** The user name in the SQL statement must exactly match the Container App resource name — this is how Azure maps the system-assigned managed identity to a database principal.

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

1. Navigate to the [Azure AI Foundry](https://ai.azure.com) portal and open the Foundry project created previously.
2. In the top navigation bar, select **Build**, then select **Agents** to view the list of agents.
3. Select the agent you created in Step 2.
4. Expand the **Tools** section.
5. Click **Add**.
6. Select **Custom**.
7. Choose **Model Context Protocol (MCP)**.
8. Click **Create**.

On the next dialog, fill in the following:

- **Name** — Provide a unique, readable name to identify this MCP connection.
- **Base URL** — Enter the FQDN of your MCP Container App. You can retrieve it by running:

  ```bash
  az containerapp show \
    --name <your-mcp-container-app-name> \
    --resource-group <your-resource-group> \
    --query "properties.configuration.ingress.fqdn" \
    --output tsv
  ```

- **Authentication** — Select **Unauthenticated**.

Click **Connect** to save the connection.

### Configure Tool Approval

Once the MCP tool is saved:

1. Click the **three dots menu** (⋯) next to the tool.
2. Select **Configure**.
3. Under **Require approval before using tools**, choose **Always approve all tools**.
4. Click **Add**.
5. Save the Agent

Your agent is now connected to the MCP tool and can use it as needed during processing.

## 7. Run the Frontend

The frontend is a static HTML/CSS/JavaScript application located in the `frontend/` folder. Before running it, update the API endpoint in `frontend/app.js` to point to your deployed API Container App:

```javascript
const API_URL = 'https://<your-api-container-app-fqdn>/query';
```

Replace `<your-api-container-app-fqdn>` with the FQDN of your API Container App. You can retrieve it by running:

```bash
az containerapp show \
  --name <your-api-container-app-name> \
  --resource-group <your-resource-group> \
  --query "properties.configuration.ingress.fqdn" \
  --output tsv
```

To run the frontend locally, serve the files with any static file server. For example, using Python:

```bash
cd frontend
python3 -m http.server 8080
```

Then open your browser to [http://localhost:8080](http://localhost:8080).

### Installing Python (if not already installed)

Check whether Python is available by running `python3 --version`. If the command is not found, follow the steps for your operating system:

**macOS**

```bash
brew install python
```

If you don't have Homebrew, install it first from [https://brew.sh](https://brew.sh).

**Windows**

Download and run the installer from [https://www.python.org/downloads/](https://www.python.org/downloads/). During installation, make sure to check **Add Python to PATH**.

Alternatively, install via `winget`:

```powershell
winget install Python.Python.3.12
```

**Linux (Debian/Ubuntu)**

```bash
sudo apt update && sudo apt install -y python3
```

**Linux (Fedora)**

```bash
sudo dnf install -y python3
```