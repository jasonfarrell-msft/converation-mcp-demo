using Farrellsoft.Examples.SurveyDataApi.Models;

namespace Farrellsoft.Examples.SurveyDataApi.Services;

public interface IAnswerService
{
    Task<QueryResponseModel> AnswerRequest(QueryRequestModel request);
}
