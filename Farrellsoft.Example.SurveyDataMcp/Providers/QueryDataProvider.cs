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
        var normalizedQuery = query?.Trim() ?? string.Empty;
        if (normalizedQuery.EndsWith(';'))
            normalizedQuery = normalizedQuery[..^1].TrimEnd();

        if (!normalizedQuery.StartsWith("SELECT", StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Only SELECT queries are allowed.");
        if (normalizedQuery.Contains(';'))
            throw new InvalidOperationException("Multiple SQL statements are not allowed.");

        var disallowedKeywords = new[]
        {
            " INSERT ", " UPDATE ", " DELETE ", " MERGE ", " DROP ",
            " ALTER ", " CREATE ", " TRUNCATE ", " EXEC "
        };
        var upperQuery = $" {normalizedQuery.ToUpperInvariant()} ";
        if (disallowedKeywords.Any(upperQuery.Contains))
            throw new InvalidOperationException("Unsafe SQL keywords are not allowed.");

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

            const int maxRows = 500;
            var command = new CommandDefinition(normalizedQuery, commandTimeout: 30);
            var results = (await connection.QueryAsync<RpnsSurveyDataRecord>(command)).Take(maxRows).ToList();
            Console.WriteLine($"Returned {results.Count} rows (max {maxRows}).");
            return results;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error connecting to SQL Server: {ex.Message}");
            throw;
        }
    }
}
