using System.Text.Json;
using System.ComponentModel;
using Farrellsoft.Examples.SurveyDataMcp.Providers;
using ModelContextProtocol.Server;

namespace Farrellsoft.Example.SurveyDataMcp.Tools;

[McpServerToolType]
public class SurveyDataTool
{
    private readonly QueryDataProvider _queryDataProvider;

    public SurveyDataTool(QueryDataProvider queryDataProvider)
    {
        _queryDataProvider = queryDataProvider;
    }

    [McpServerTool, Description("Executes a query to return data from Survey Data database")]
    public async Task<string> ExecuteQuery(
        [Description("The SQL query to execute")] string query)
    {
        try
        {
            var results = await _queryDataProvider.QueryAsync(query);
            
            // Serialize using the custom JSON converter (already applied via attribute on RpnsSurveyDataRecord)
            var jsonOptions = new JsonSerializerOptions
            {
                WriteIndented = true
            };

            return JsonSerializer.Serialize(results, jsonOptions);
        }
        catch (Exception ex)
        {
            return $"Error executing query: {ex.Message}";
        }
    }
}
