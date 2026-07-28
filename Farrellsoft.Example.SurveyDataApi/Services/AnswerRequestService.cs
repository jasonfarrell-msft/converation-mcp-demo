using Azure.AI.Projects;
using Azure.Identity;
using System.ClientModel;
using System.ClientModel.Primitives;
using System.Text.Json;
using Farrellsoft.Examples.SurveyDataApi.Models;

#pragma warning disable OPENAI001

namespace Farrellsoft.Examples.SurveyDataApi.Services;

public class AnswerRequestService(IConfiguration configuration) : IAnswerService
{
    public async Task<QueryResponseModel> AnswerRequest(QueryRequestModel request)
    {
        var projectClient = new AIProjectClient(
            endpoint: new Uri(configuration["FoundryEndpoint"]), tokenProvider: new DefaultAzureCredential());

        var conversation = string.IsNullOrEmpty(request.ThreadId)
            ? (await projectClient.OpenAI.Conversations.CreateProjectConversationAsync()).Value
            : (await projectClient.OpenAI.Conversations.GetProjectConversationAsync(request.ThreadId)).Value;

        var responseClient = projectClient.OpenAI.GetProjectResponsesClientForAgent(
            configuration["AgentName"]!,
            conversation.Id
        );

        var response = await CreateResponseWithRateLimitRetry(responseClient, request.Request);

        var text = response?.GetOutputText();
        if (string.IsNullOrEmpty(text) && response != null)
            text = ExtractTextFromRawResponse(response);

        return new QueryResponseModel
        {
            Response = text ?? "I’m temporarily rate-limited right now. Please retry your question in a moment.",
            ThreadId = conversation.Id
        };
    }

    private static async Task<OpenAI.Responses.ResponseResult?> CreateResponseWithRateLimitRetry(
        OpenAI.Responses.ResponsesClient responseClient,
        string request)
    {
        var retryDelays = new[] { 500, 1500 };

        for (var attempt = 0; attempt <= retryDelays.Length; attempt++)
        {
            try
            {
                return (await responseClient.CreateResponseAsync(request))?.Value;
            }
            catch (ClientResultException ex) when (ex.Status == 429)
            {
                if (attempt >= retryDelays.Length)
                    return null;

                await Task.Delay(retryDelays[attempt]);
            }
        }

        return null;
    }

    private static string? ExtractTextFromRawResponse(OpenAI.Responses.ResponseResult response)
    {
        try
        {
            var raw = ModelReaderWriter.Write(response).ToString();
            var doc = JsonDocument.Parse(raw);
            if (!doc.RootElement.TryGetProperty("output", out var output))
                return null;

            var texts = new List<string>();
            foreach (var item in output.EnumerateArray())
            {
                if (!item.TryGetProperty("type", out var typeProp)) continue;
                var type = typeProp.GetString();
                if (type != "message") continue;

                if (!item.TryGetProperty("content", out var content)) continue;
                foreach (var contentItem in content.EnumerateArray())
                {
                    if (contentItem.TryGetProperty("text", out var textProp))
                        texts.Add(textProp.GetString() ?? "");
                }
            }
            return texts.Count > 0 ? string.Join("\n", texts) : null;
        }
        catch (Exception ex) when (ex is JsonException or InvalidOperationException)
        {
            return null;
        }
    }
}
