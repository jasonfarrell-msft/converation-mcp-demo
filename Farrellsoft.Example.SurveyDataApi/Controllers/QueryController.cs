using Microsoft.AspNetCore.Mvc;
using Farrellsoft.Examples.SurveyDataApi.Models;
using Farrellsoft.Examples.SurveyDataApi.Services;

namespace Farrellsoft.Examples.SurveyDataApi.Controllers;

[ApiController]
[Route("[controller]")]
public class QueryController(IAnswerService queryService) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Post([FromBody] QueryRequestModel model)
    {
        var answer = await queryService.AnswerRequest(model);
        return Ok(answer);
    }
}
