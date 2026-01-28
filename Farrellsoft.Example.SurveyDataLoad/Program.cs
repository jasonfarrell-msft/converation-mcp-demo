using System.Globalization;
using CsvHelper;
using CsvHelper.Configuration;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Farrellsoft.Example.SurveyDataLoad.Models;
using Farrellsoft.Example.SurveyDataLoad.Data;
using Farrellsoft.Example.SurveyDataLoad.Entities;

const string csvFilePath = "Dashboard_Export_RNPS_2025.csv";

// Helper method to convert sentiment text to numeric rating
static short? ConvertSentimentToRating(string? sentiment)
{
    if (string.IsNullOrWhiteSpace(sentiment))
        return null;

    return sentiment.Trim().ToLowerInvariant() switch
    {
        "promoter" => 1,
        "passive" => 0,
        "detractor" => -1,
        _ => null
    };
}

// Load configuration
var configuration = new ConfigurationBuilder()
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddUserSecrets<Program>()
    .Build();

var connectionString = configuration["ConnectionStrings:SurveyDatabase"];

// Read CSV
var config = new CsvConfiguration(CultureInfo.InvariantCulture)
{
    HeaderValidated = null,
    MissingFieldFound = null
};

using var reader = new StreamReader(csvFilePath);
using var csv = new CsvReader(reader, config);

csv.Context.TypeConverterOptionsCache.GetOptions<short?>().NullValues.Add("null");
csv.Context.TypeConverterOptionsCache.GetOptions<string>().NullValues.Add("null");

csv.Context.RegisterClassMap<RnpsSurveyResultMap>();

var records = csv.GetRecords<RnpsSurveyResult>().ToList();

Console.WriteLine($"Total records loaded from CSV: {records.Count}");

// Convert to entities and insert into database
var optionsBuilder = new DbContextOptionsBuilder<SurveyDbContext>();
optionsBuilder.UseSqlServer(connectionString);

using var dbContext = new SurveyDbContext(optionsBuilder.Options);

var entities = records.Select(r => new RnpsSurveyRecord
{
    RecordId = RnpsSurveyRecord.GenerateRecordId(r.PartnerId, r.Name, r.SurveyMonth, r.SurveyYear, r.SurveySeason),
    Age = r.Age,
    PartnerId = r.PartnerId,
    Name = r.Name,
    IsLowIncome = r.IsLowIncome,
    City = r.City,
    ZipCode = r.ZipCode,
    ReliabilityRating = ConvertSentimentToRating(r.ReliabilityRating),
    ReliabilityComment = r.ReliabilityComment,
    PriceRating = ConvertSentimentToRating(r.PriceRating),
    PriceComment = r.PriceComment,
    TransparencyRating = ConvertSentimentToRating(r.TransparencyRating),
    TransparencyComment = r.TransparencyComment,
    OverallRating = ConvertSentimentToRating(r.OverallRating),
    SurveyDate = r.SurveyDate,
    SurveyMonth = r.SurveyMonth,
    SurveyYear = r.SurveyYear,
    SurveySeason = r.SurveySeason
}).ToList();

Console.WriteLine($"Adding {entities.Count} records to database...");

await dbContext.RnpsSurveyRecords.AddRangeAsync(entities);
var savedCount = await dbContext.SaveChangesAsync();

Console.WriteLine($"Successfully inserted {savedCount} records into RnpsSurveyRecords table.");
