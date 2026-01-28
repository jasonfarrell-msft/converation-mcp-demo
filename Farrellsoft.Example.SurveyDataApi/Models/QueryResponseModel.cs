namespace Farrellsoft.Examples.SurveyDataApi.Models;

public record QueryResponseModel
{
    public required string Response { get; init; }
    public required string ThreadId { get; init; }
}
