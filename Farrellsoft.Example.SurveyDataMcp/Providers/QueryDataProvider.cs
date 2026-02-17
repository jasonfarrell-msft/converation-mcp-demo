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
            DataSource = $"tcp:{_server},1433",
            InitialCatalog = _database,
            Encrypt = true,
            TrustServerCertificate = false,
            PersistSecurityInfo = false,
            MultipleActiveResultSets = false,
            Authentication = SqlAuthenticationMethod.ActiveDirectoryDefault
        }.ConnectionString;

        Console.WriteLine($"Connecting to SQL Server with connection string: {connectionString}");
        try
        {
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        var results = await connection.QueryAsync<RpnsSurveyDataRecord>(query);
        return results.ToList();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error connecting to SQL Server: {ex.Message}");
            throw;
        }
    }
}
