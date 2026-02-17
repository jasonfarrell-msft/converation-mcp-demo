using Farrellsoft.Example.SurveyDataMcp.Tools;
using Farrellsoft.Examples.SurveyDataMcp.Providers;

var builder = WebApplication.CreateBuilder(args);

// Register QueryDataProvider with SQL Server and database from configuration
var sqlServer = builder.Configuration["SqlServer"] 
    ?? throw new InvalidOperationException("'SqlServer' configuration value not found.");
var sqlDatabase = builder.Configuration["SqlDatabase"] 
    ?? throw new InvalidOperationException("'SqlDatabase' configuration value not found.");
builder.Services.AddSingleton(new QueryDataProvider(sqlServer, sqlDatabase));

// Add MCP server services with HTTP/SSE transport
builder.Services
    .AddMcpServer()
    .WithHttpTransport()
    .WithToolsFromAssembly();

// Add logging for debugging
builder.Logging.SetMinimumLevel(LogLevel.Debug);

var app = builder.Build();

// Map MCP endpoints (creates /mcp for SSE and /mcp/message for JSON-RPC)
app.MapMcp();

app.MapGet("/healthz", () => Results.Ok("I am working"));

app.MapGet("/test", async (QueryDataProvider provider) =>
{
    try
    {
        await provider.QueryAsync("SELECT 1");
        return Results.Ok("Successfully connected to SQL Server");
    }
    catch (Exception ex)
    {
        return Results.Problem($"Failed to connect to SQL Server: {ex.Message}");
    }
});

app.Run();
