namespace Farrellsoft.Example.SurveyDataLoad.Models;

public class RnpsSurveyResult
{
    public short? Age { get; set; }
    public long PartnerId { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsLowIncome { get; set; }
    public string City { get; set; } = string.Empty;
    public string ZipCode { get; set; } = string.Empty;
    public string ReliabilityRating { get; set; } = string.Empty;
    public string? ReliabilityComment { get; set; }
    public string PriceRating { get; set; } = string.Empty;
    public string? PriceComment { get; set; }
    public string TransparencyRating { get; set; } = string.Empty;
    public string? TransparencyComment { get; set; }
    public string OverallRating { get; set; } = string.Empty;
    public DateTime SurveyDate { get; set; }
    public string SurveyMonth { get; set; } = string.Empty;
    public short SurveyYear { get; set; }
    public string SurveySeason { get; set; } = string.Empty;
}
