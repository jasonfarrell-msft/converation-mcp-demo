# Survey Data Application Setup

This guide will walk you through setting up the Survey Data Application infrastructure and services.

## Prerequisites

- Azure CLI installed and configured
- Azure subscription with appropriate permissions
- .NET 8.0 SDK or later
- Docker (optional, for containerized deployments)

## Section 1: Setup Azure

### Step 1: Configure Environment Variables

Set the following environment variables in your shell:

```bash
# Create a unique 4-digit suffix for your resources (e.g., 1234, 5678)
export SUFFIX="1234"

# Set your Azure region shorthand (e.g., eastus2, westus2, centralus)
export LOCATION_SHORT="eastus2"

# Set your resource group name
export RG_NAME="rg-surveydata-${LOCATION_SHORT}-${SUFFIX}"

# Set your storage account name (must be 3-24 chars, lowercase and numbers only)
export STORAGE_ACCOUNT_NAME="stsurvey${LOCATION_SHORT}${SUFFIX}"

# Set your container registry name (must be 5-50 chars, alphanumeric only)
export REGISTRY_NAME="crsurvey${LOCATION_SHORT}${SUFFIX}"

# Set image names for the containers
export API_IMAGE_NAME="surveydata-api"
export MCP_IMAGE_NAME="surveydata-mcp"

# Set image tag version
export IMAGE_TAG="v1"

# Set container environment and app names
export CONTAINER_ENV_NAME="cae-surveydata-${LOCATION_SHORT}-${SUFFIX}"
export API_APP_NAME="ca-surveydata-api-${LOCATION_SHORT}-${SUFFIX}"
export MCP_APP_NAME="ca-surveydata-mcp-${LOCATION_SHORT}-${SUFFIX}"

# Set Foundry hub and project names
export FOUNDRY_INSTANCE_NAME="aih-surveydata-${LOCATION_SHORT}-${SUFFIX}"
export FOUNDRY_PROJECT_NAME="aiproj-surveydata-${LOCATION_SHORT}-${SUFFIX}"
```

**Environment Variable Details:**
- `SUFFIX`: A unique 4-digit code to ensure resource names are globally unique
- `LOCATION_SHORT`: The Azure region shorthand where resources will be deployed
  - Examples: `eastus2`, `westus2`, `centralus`, `westeurope`
- `RG_NAME`: The name of the resource group that will contain all Azure resources
- `STORAGE_ACCOUNT_NAME`: The globally unique name for the Azure Storage account
- `REGISTRY_NAME`: The globally unique name for the Azure Container Registry
- `API_IMAGE_NAME`: The name for the API container image
- `MCP_IMAGE_NAME`: The name for the MCP server container image
- `IMAGE_TAG`: The version tag for the container images
- `CONTAINER_ENV_NAME`: The name for the Container Apps Environment
- `API_APP_NAME`: The name for the API Container App
- `MCP_APP_NAME`: The name for the MCP Container App
- `FOUNDRY_INSTANCE_NAME`: The name for the Azure AI Foundry instance
- `FOUNDRY_PROJECT_NAME`: The name for the Azure AI Foundry project

You can verify your environment variables are set correctly:

```bash
echo "Suffix: $SUFFIX"
echo "Location: $LOCATION_SHORT"
echo "Resource Group: $RG_NAME"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Container Registry: $REGISTRY_NAME"
echo "API Image: $API_IMAGE_NAME:$IMAGE_TAG"
echo "MCP Image: $MCP_IMAGE_NAME:$IMAGE_TAG"
echo "Container Environment: $CONTAINER_ENV_NAME"
echo "API Container App: $API_APP_NAME"
echo "MCP Container App: $MCP_APP_NAME"
echo "Foundry Instance: $FOUNDRY_INSTANCE_NAME"
echo "Foundry Project: $FOUNDRY_PROJECT_NAME"
```

### Step 2: Create the Resource Group

Create the Azure resource group that will contain all your resources:

```bash
az group create --name $RG_NAME --location $LOCATION_SHORT
```

This command will create a new resource group in your specified Azure region. You should see output confirming the resource group was created successfully.

### Step 3: Create the Storage Account

Create an Azure Storage Account for the application data:

```bash
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION_SHORT \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2 \
  --https-only true
```

This creates a secure storage account with:
- Standard locally-redundant storage (LRS)
- Hot access tier for frequently accessed data
- Public blob access disabled for security
- TLS 1.2 minimum and HTTPS-only connections

### Step 4: Create the Container Registry

Create an Azure Container Registry for storing container images:

```bash
az acr create \
  --name $REGISTRY_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION_SHORT \
  --sku Standard \
  --admin-enabled true
```

This creates a container registry with:
- Standard SKU for cost-effective container storage
- Admin access enabled for container deployments

### Step 5: Build and Push Container Images

Build the container images directly in Azure Container Registry. Run these commands from the project root:

```bash
# Build and push the Survey Data API image
az acr build \
  --registry $REGISTRY_NAME \
  --image $API_IMAGE_NAME:$IMAGE_TAG \
  --file Farrellsoft.Example.SurveyDataApi/Dockerfile \
  ./Farrellsoft.Example.SurveyDataApi

# Build and push the Survey Data MCP server image
az acr build \
  --registry $REGISTRY_NAME \
  --image $MCP_IMAGE_NAME:$IMAGE_TAG \
  --file Farrellsoft.Example.SurveyDataMcp/Dockerfile \
  ./Farrellsoft.Example.SurveyDataMcp
```

Verify the images were pushed successfully:

```bash
az acr repository list --name $REGISTRY_NAME --output table
```

### Step 6: Create Container Apps Environment

Create a Container Apps Environment to host your container applications:

```bash
az containerapp env create \
  --name $CONTAINER_ENV_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION_SHORT
```

### Step 7: Create API Container App

Deploy the Survey Data API as a Container App:

```bash
az containerapp create \
  --name $API_APP_NAME \
  --resource-group $RG_NAME \
  --environment $CONTAINER_ENV_NAME \
  --image ${REGISTRY_NAME}.azurecr.io/${API_IMAGE_NAME}:${IMAGE_TAG} \
  --registry-server ${REGISTRY_NAME}.azurecr.io \
  --target-port 8080 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 10 \
  --cpu 0.5 \
  --memory 1.0Gi \
  --system-assigned
```

### Step 8: Create MCP Container App

Deploy the Survey Data MCP server as a Container App:

```bash
az containerapp create \
  --name $MCP_APP_NAME \
  --resource-group $RG_NAME \
  --environment $CONTAINER_ENV_NAME \
  --image ${REGISTRY_NAME}.azurecr.io/${MCP_IMAGE_NAME}:${IMAGE_TAG} \
  --registry-server ${REGISTRY_NAME}.azurecr.io \
  --target-port 8080 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 10 \
  --cpu 0.5 \
  --memory 1.0Gi \
  --system-assigned
```

Both container apps are configured with:
- Public ingress on port 8080
- Auto-scaling from 1 to 10 replicas
- 0.5 CPU cores and 1GB memory per replica
- System-assigned managed identity enabled

### Step 9: Assign AcrPull Role to Container Apps

Grant the container apps permission to pull images from the container registry:

```bash
# Get the API container app's managed identity principal ID
API_PRINCIPAL_ID=$(az containerapp show \
  --name $API_APP_NAME \
  --resource-group $RG_NAME \
  --query identity.principalId \
  --output tsv)

# Get the MCP container app's managed identity principal ID
MCP_PRINCIPAL_ID=$(az containerapp show \
  --name $MCP_APP_NAME \
  --resource-group $RG_NAME \
  --query identity.principalId \
  --output tsv)

# Get the container registry resource ID
REGISTRY_ID=$(az acr show \
  --name $REGISTRY_NAME \
  --resource-group $RG_NAME \
  --query id \
  --output tsv)

# Assign AcrPull role to API container app identity
az role assignment create \
  --assignee $API_PRINCIPAL_ID \
  --role AcrPull \
  --scope $REGISTRY_ID

# Assign AcrPull role to MCP container app identity
az role assignment create \
  --assignee $MCP_PRINCIPAL_ID \
  --role AcrPull \
  --scope $REGISTRY_ID
```

This grants both container apps the AcrPull role, allowing them to securely pull images from the container registry using their managed identities.

### Step 10: Disable Container Registry Admin Access

Now that managed identities are configured, disable admin access for improved security:

```bash
az acr update \
  --name $REGISTRY_NAME \
  --resource-group $RG_NAME \
  --admin-enabled false
```

This ensures that only Azure AD authentication (via managed identities) can be used to access the container registry.

### Step 11: Deploy Azure AI Foundry Instance

First, get the MCP Container App URL:

```bash
export MCP_URL=$(az containerapp show \
  --name $MCP_APP_NAME \
  --resource-group $RG_NAME \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

echo "MCP URL: https://$MCP_URL"
```

Then deploy the Azure AI Foundry instance and project using the Bicep template:

```bash
az deployment group create \
  --resource-group $RG_NAME \
  --template-file infra/foundry.bicep \
  --parameters instanceName=$FOUNDRY_INSTANCE_NAME projectName=$FOUNDRY_PROJECT_NAME location=$LOCATION_SHORT mcpUrl=https://$MCP_URL
```

This creates an Azure AI Foundry instance, project, and a connection to the MCP server for AI model deployment and management.

## Section 2: Setup Foundry

### 1. Access the Foundry Portal

Open your Foundry instance:

1. Navigate to https://portal.azure.com
2. Sign in with your Azure credentials
3. Search for your Foundry instance name (value of `$FOUNDRY_INSTANCE_NAME`)
4. Select the Azure AI Foundry resource from the search results
5. On the Overview page, click the "Launch studio" button to access the Foundry Portal
6. In the Foundry Portal, ensure the new Foundry experience is enabled by using the switch in the title bar
7. Select your project (named with the value of `$FOUNDRY_PROJECT_NAME`)

### 2. Create an Agent

Create an agent through the Azure AI Foundry Studio:

1. In the upper navigation bar, click "Build"
2. In your project, go to "Agents" in the left navigation
3. Click "New agent" or "Create agent"
4. Configure the agent:
   - **Name**: `survey-data-agent`
   - **Model**: Select a chat model (e.g., `gpt-4o-mini`, `gpt-4o`, or `gpt-4`)
   - **Instructions**: Add the following system instructions:
     ```
     You are a helpful assistant with knowledge about surveys related to the Electrification industry.

     You dont answer questions outside those relating to data for the survey and customers. If a request comes in that is outside your scope of answering, politely decline to answer.
             
     # Step 1: Generate a SQL Query to gather results for the User Request
     The Table structure looks like this:
     <Insert DDL for Create table on target table(s)>

     ## Rules
     <Indicate special rules for how data in the various columns should be interpreted>

     When generating SQL following these rules:
     - Do NOT use GROUP BY clauses
     - Do NOT use TOP
     - Do NOT use aggregation functions (AVG, SUM, COUNT, MAX, MIN)
     - Do NOT use HAVING clauses
     - Generate only SELECT queries that return individual records (rows) with only the columns from the schema above
     - DTE is the name of the power company and not a customer. If mentioned ignore and do not filter on it.

     # Step 2: Generate a response
     Pass the query to associated Tool. You will receive a JSON response containing the data for the request. Follow these rules when responding:
     - Use only the data provided
     - Respond to questions from the user accurately and in a human-like way with the data results provided
     - The response should be natural sounding, friendly and conversational.

     ## Examples
     Example 1:
     User asks: 'how many surveys were given to detroit, Ferndale, dearborn heights, and grand rapids'
     Data received shows 634 surveys for Detroit, 266 for Grand Rapids, 44 for Dearborn Heights, and 20 for Ferndale.
     Response should be:
       A total of 964 surveys were given out among the given cities. Here is a breakdown:
         - Detroit: 634 surveys
         - Grand Rapids: 266 surveys
         - Dearborn Heights: 44 surveys
         - Ferndale: 20 surveys
       Would you like to know more?
             
     Example 2:
     Users asks: what is the worst thing customers in detroit have said about DTE
     Data received shows 150 customers mentioned high prices, 100 mentioned poor customer service, and 50 mentioned outages.
     Response should be limited to the three most common complaints by theme:
     Detroit customers' worst feedback about DTE consistently centers on:
       • Extremely high and increasing bills, often described as unjustified, egregious, or outrageous, including charges of $200–$800+ per month for small apartments or single-person households  
       • Bills rising sharply despite little or no change in usage, with some customers reporting doubled or tripled costs or unexplained jumps from $100 to $300+  
       • Lack of transparency around pricing, fees, peak-hour charges, and rate increases, with many customers saying DTE cannot clearly explain why bills are so high

     Would you like to know more?

     ## Content Rules
     Ensure the following rules are followed for the content of the response:
     - Never include customers personally identifiable information in the response (no address, last name, phone number, email, etc).
     - When representing numbers use numerals. Do not spell out the number.

     Respond in markdown format only. No extra commentary or citation.
     ```
   - **Description**: `AI assistant for analyzing survey data`
5. Click "Create" or "Save"

### 3. Verify the MCP Connection

Check that the MCP server connection is configured:

1. In your project, go to "Connected resources" or "Connections" in the left navigation
2. Verify that the MCP server connection is listed
3. The connection should point to your MCP Container App URL

### 4. Test the Agent

Test the agent in the playground:

1. In your project, go to "Agents" in the left navigation
2. Select the `survey-data-agent` agent you created
3. Click "Test in playground" or "Open in playground"
4. Try asking a question about the survey data
5. Verify that the agent can access the MCP tools and query the data

## Section 3: API Development

### Running the API Locally

```bash
cd Farrellsoft.Example.SurveyDataApi
dotnet run
```

### Configuration

The API requires database configuration in `appsettings.json` or user secrets.

## Next Steps

Further setup instructions will be added as the deployment process is finalized.
