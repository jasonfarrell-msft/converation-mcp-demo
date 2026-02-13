using Azure.Identity;
using Dapper;
using Farrellsoft.Examples.SurveyDataMcp.Entities;
using Microsoft.Data.SqlClient;

namespace Farrellsoft.Examples.SurveyDataMcp.Providers;

public class QueryDataProvider
{
    private readonly string _server;
    private readonly string _database;

    public QueryDataProvider(string server, string database)
    {
        _server = server;
        _database = database;
    }

    public async Task<List<RpnsSurveyDataRecord>> QueryAsync(string query)
    {
        var connectionString = new SqlConnectionStringBuilder
        {
            DataSource = _server,
            InitialCatalog = _database,
            Encrypt = true,
            TrustServerCertificate = false
        }.ConnectionString;

        await using var connection = new SqlConnection(connectionString);
        var credential = new DefaultAzureCredential();
        connection.AccessToken = (await credential.GetTokenAsync(
            new Azure.Core.TokenRequestContext(["https://database.windows.net/.default"]))).Token;

        await connection.OpenAsync();

        var results = await connection.QueryAsync<RpnsSurveyDataRecord>(query);
        return results.ToList();
    }
}
