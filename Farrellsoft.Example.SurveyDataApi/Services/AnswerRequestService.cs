using Azure;
using Azure.AI.Projects;
using Azure.Identity;
using Farrellsoft.Examples.SurveyDataApi.Models;

namespace Farrellsoft.Examples.SurveyDataApi.Services;

public class AnswerRequestService(IConfiguration configuration) : IAnswerService
{
    public async Task<QueryResponseModel> AnswerRequest(QueryRequestModel request)
    {
        var projectClient = new AIProjectClient(
            endpoint: new Uri(configuration["FoundryEndpoint"]), tokenProvider: new DefaultAzureCredential());

        var agentRecord = (await projectClient.Agents.GetAgentAsync(configuration["AgentName"])).Value;
        var conversation = string.IsNullOrEmpty(request.ThreadId)
            ? (await projectClient.OpenAI.Conversations.CreateProjectConversationAsync()).Value
            : (await projectClient.OpenAI.Conversations.GetProjectConversationAsync(request.ThreadId)).Value;

        var responseClient = projectClient.OpenAI.GetProjectResponsesClientForAgent(
            agentRecord.Name, 
            conversation.Id
        );

        var response = (await responseClient.CreateResponseAsync(request.Request))?.Value;
        return new QueryResponseModel
        {
            Response = response.GetOutputText(),
            ThreadId = conversation.Id
        };
    }
}
