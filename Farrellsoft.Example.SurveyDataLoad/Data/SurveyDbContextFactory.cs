using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace Farrellsoft.Example.SurveyDataLoad.Data;

public class SurveyDbContextFactory : IDesignTimeDbContextFactory<SurveyDbContext>
{
    public SurveyDbContext CreateDbContext(string[] args)
    {
        var configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddUserSecrets<SurveyDbContextFactory>()
            .Build();

        var optionsBuilder = new DbContextOptionsBuilder<SurveyDbContext>();
        var connectionString = configuration["ConnectionStrings:SurveyDatabase"];
        
        optionsBuilder.UseSqlServer(connectionString);

        return new SurveyDbContext(optionsBuilder.Options);
    }
}
