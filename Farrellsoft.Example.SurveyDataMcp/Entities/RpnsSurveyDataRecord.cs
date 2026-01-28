
using System.Text.Json.Serialization;
using Farrellsoft.Examples.SurveyDataMcp.Utilities;

namespace Farrellsoft.Examples.SurveyDataMcp.Entities;

[JsonConverter(typeof(SurveyRecordJsonConverter))]
public class RpnsSurveyDataRecord
{
    public Guid RecordId { get; set; }
    public short? Age { get; set; }
    public long? PartnerId { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool? IsLowIncome { get; set; }
    public string City { get; set; } = string.Empty;
    public string ZipCode { get; set; } = string.Empty;
    public short? ReliabilityRating { get; set; }
    public string? ReliabilityComment { get; set; }
    public short? PriceRating { get; set; }
    public string? PriceComment { get; set; }
    public short? TransparencyRating { get; set; }
    public string? TransparencyComment { get; set; }
    public short? OverallRating { get; set; }
    public DateTime SurveyDate { get; set; }
    public string? SurveyMonth { get; set; } = string.Empty;
    public short? SurveyYear { get; set; }
    public string? SurveySeason { get; set; } = string.Empty;
}
