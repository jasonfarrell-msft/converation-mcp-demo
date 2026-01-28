using Microsoft.EntityFrameworkCore;
using Farrellsoft.Example.SurveyDataLoad.Entities;

namespace Farrellsoft.Example.SurveyDataLoad.Data;

public class SurveyDbContext : DbContext
{
    public DbSet<RnpsSurveyRecord> RnpsSurveyRecords { get; set; }

    public SurveyDbContext(DbContextOptions<SurveyDbContext> options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<RnpsSurveyRecord>(entity =>
        {
            entity.HasKey(e => e.RecordId);
            entity.ToTable("RnpsSurveyRecords");
        });

        base.OnModelCreating(modelBuilder);
    }
}
