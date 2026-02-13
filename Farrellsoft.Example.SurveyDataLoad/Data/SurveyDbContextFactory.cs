using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Farrellsoft.Example.SurveyDataLoad.Data;

public class SurveyDbContextFactory : IDesignTimeDbContextFactory<SurveyDbContext>
{
    public SurveyDbContext CreateDbContext(string[] args)
    {
        var server = GetArgValue(args, "--server")
            ?? throw new InvalidOperationException("Missing required argument: --server");
        var database = GetArgValue(args, "--database")
            ?? throw new InvalidOperationException("Missing required argument: --database");

        var connectionString = $"Server=tcp:{server},1433;Initial Catalog={database};Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Default;";

        var optionsBuilder = new DbContextOptionsBuilder<SurveyDbContext>();
        optionsBuilder.UseSqlServer(connectionString);

        return new SurveyDbContext(optionsBuilder.Options);
    }

    private static string? GetArgValue(string[] args, string key)
    {
        for (int i = 0; i < args.Length - 1; i++)
        {
            if (args[i].Equals(key, StringComparison.OrdinalIgnoreCase))
                return args[i + 1];
        }
        return null;
    }
}
