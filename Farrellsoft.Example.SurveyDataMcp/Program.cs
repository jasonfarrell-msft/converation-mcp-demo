using Farrellsoft.Example.SurveyDataMcp.Tools;
using Farrellsoft.Examples.SurveyDataMcp.Providers;

var builder = WebApplication.CreateBuilder(args);

// Register QueryDataProvider with connection string from configuration
var connectionString = builder.Configuration["SqlConnectionString"] 
    ?? throw new InvalidOperationException("Connection string 'SqlConnectionString' not found.");
builder.Services.AddSingleton(new QueryDataProvider(connectionString));

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

app.Run();
