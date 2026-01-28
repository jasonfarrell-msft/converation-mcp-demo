using System.ComponentModel.DataAnnotations;
using System.Security.Cryptography;
using System.Text;

namespace Farrellsoft.Example.SurveyDataLoad.Entities;

public class RnpsSurveyRecord
{
    [Key]
    public Guid RecordId { get; set; }
    public short? Age { get; set; }
    public long PartnerId { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool? IsLowIncome { get; set; }
    public string? City { get; set; }
    public string? ZipCode { get; set; }
    public short? ReliabilityRating { get; set; }
    public string? ReliabilityComment { get; set; }
    public short? PriceRating { get; set; }
    public string? PriceComment { get; set; }
    public short? TransparencyRating { get; set; }
    public string? TransparencyComment { get; set; }
    public short? OverallRating { get; set; }
    public DateTime SurveyDate { get; set; }
    public string SurveyMonth { get; set; } = string.Empty;
    public short SurveyYear { get; set; }
    public string SurveySeason { get; set; } = string.Empty;

    public static Guid GenerateRecordId(long partnerId, string name, string month, short year, string season)
    {
        var input = $"{partnerId}|{name}|{month}|{year}|{season}";
        var hash = MD5.HashData(Encoding.UTF8.GetBytes(input));
        return new Guid(hash);
    }
}
