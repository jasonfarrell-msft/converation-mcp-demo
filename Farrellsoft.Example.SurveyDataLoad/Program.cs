using System.Globalization;
using CsvHelper;
using CsvHelper.Configuration;
using Microsoft.EntityFrameworkCore;
using Farrellsoft.Example.SurveyDataLoad.Models;
using Farrellsoft.Example.SurveyDataLoad.Data;
using Farrellsoft.Example.SurveyDataLoad.Entities;

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

static string? GetArgValue(string[] args, string key)
{
    for (int i = 0; i < args.Length - 1; i++)
        if (args[i].Equals(key, StringComparison.OrdinalIgnoreCase))
            return args[i + 1];
    return null;
}

var server   = GetArgValue(args, "--server")   ?? throw new InvalidOperationException("Missing required argument: --server");
var database = GetArgValue(args, "--database") ?? throw new InvalidOperationException("Missing required argument: --database");
var folder   = GetArgValue(args, "--folder")   ?? ".";

if (!Directory.Exists(folder))
    throw new DirectoryNotFoundException($"Folder not found: {folder}");

// Only process .csv files; silently ignore everything else
var csvFiles = Directory.GetFiles(folder, "*", SearchOption.TopDirectoryOnly)
    .Where(f => Path.GetExtension(f).Equals(".csv", StringComparison.OrdinalIgnoreCase))
    .OrderBy(f => f)
    .ToArray();

Console.WriteLine($"Found {csvFiles.Length} .csv file(s) in: {folder}");

var config = new CsvConfiguration(CultureInfo.InvariantCulture)
{
    HeaderValidated = null,
    MissingFieldFound = null
};

var allEntities = new List<RnpsSurveyRecord>();

foreach (var csvPath in csvFiles)
{
    Console.WriteLine($"  Reading: {Path.GetFileName(csvPath)}");

    using var reader = new StreamReader(csvPath);
    using var csv = new CsvReader(reader, config);

    csv.Context.TypeConverterOptionsCache.GetOptions<short?>().NullValues.Add("null");
    csv.Context.TypeConverterOptionsCache.GetOptions<string>().NullValues.Add("null");
    csv.Context.RegisterClassMap<RnpsSurveyResultMap>();

    var records = csv.GetRecords<RnpsSurveyResult>().ToList();
    Console.WriteLine($"    {records.Count} record(s) parsed");

    allEntities.AddRange(records.Select(r => new RnpsSurveyRecord
    {
        RecordId             = RnpsSurveyRecord.GenerateRecordId(r.PartnerId, r.SurveyMonth, r.SurveyYear, r.SurveySeason),
        Age                  = r.Age,
        PartnerId            = r.PartnerId,
        IsLowIncome          = r.IsLowIncome,
        City                 = r.City,
        ZipCode              = r.ZipCode,
        ReliabilityRating    = ConvertSentimentToRating(r.ReliabilityRating),
        ReliabilityComment   = r.ReliabilityComment,
        PriceRating          = ConvertSentimentToRating(r.PriceRating),
        PriceComment         = r.PriceComment,
        TransparencyRating   = ConvertSentimentToRating(r.TransparencyRating),
        TransparencyComment  = r.TransparencyComment,
        OverallRating        = ConvertSentimentToRating(r.OverallRating),
        SurveyDate           = r.SurveyDate,
        SurveyMonth          = r.SurveyMonth,
        SurveyYear           = r.SurveyYear,
        SurveySeason         = r.SurveySeason
    }));
}

Console.WriteLine($"\nTotal records to insert: {allEntities.Count}");
if (allEntities.Count == 0) { Console.WriteLine("Nothing to insert."); return; }

var connectionString = $"Server=tcp:{server},1433;Initial Catalog={database};Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Default;";
var optionsBuilder = new DbContextOptionsBuilder<SurveyDbContext>();
optionsBuilder.UseSqlServer(connectionString);

using var dbContext = new SurveyDbContext(optionsBuilder.Options);

await dbContext.RnpsSurveyRecords.AddRangeAsync(allEntities);
var savedCount = await dbContext.SaveChangesAsync();

Console.WriteLine($"Successfully inserted {savedCount} records into RnpsSurveyRecords.");
