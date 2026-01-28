using System.ComponentModel.DataAnnotations;

namespace Farrellsoft.Examples.SurveyDataApi.Models;

public record QueryRequestModel
{
    [Required(AllowEmptyStrings = false)]
    public required string Request { get; init; }
    
    public string? ThreadId { get; init; }
}
