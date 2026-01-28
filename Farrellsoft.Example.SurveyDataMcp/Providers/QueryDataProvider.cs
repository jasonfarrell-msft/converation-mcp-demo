using Dapper;
using Farrellsoft.Examples.SurveyDataMcp.Entities;
using Microsoft.Data.SqlClient;

namespace Farrellsoft.Examples.SurveyDataMcp.Providers;

public class QueryDataProvider
{
    private readonly string _connectionString;

    public QueryDataProvider(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task<List<RpnsSurveyDataRecord>> QueryAsync(string query)
    {
        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var results = await connection.QueryAsync<RpnsSurveyDataRecord>(query);
        return results.ToList();
    }
}
