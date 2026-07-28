#pragma warning disable CA2252
using Azure.AI.Projects;
using Azure.Identity;
using System.ClientModel.Primitives;
using System.Text.Json;

var endpoint = "https://foundry-surveychat-swc01.services.ai.azure.com/api/projects/foundry-surveychat-swc01-project";
var client = new AIProjectClient(new Uri(endpoint), new DefaultAzureCredential());

var conversation = (await client.OpenAI.Conversations.CreateProjectConversationAsync()).Value;
var responseClient = client.OpenAI.GetProjectResponsesClientForAgent("surveychat-agent", conversation.Id);
var result = await responseClient.CreateResponseAsync("How many surveys are in the database?");

var response = result?.Value;
Console.WriteLine($"OutputText: '{response?.GetOutputText()}'");

// Get raw JSON of each output item
if (response != null)
{
    var raw = ModelReaderWriter.Write(response).ToString();
    var doc = JsonDocument.Parse(raw);
    
    // Print output array fully
    if (doc.RootElement.TryGetProperty("OutputItems", out var items))
    {
        Console.WriteLine($"\nOutputItems count: {items.GetArrayLength()}");
        foreach (var item in items.EnumerateArray())
        {
            Console.WriteLine($"\n--- Item ---");
            Console.WriteLine(JsonSerializer.Serialize(item, new JsonSerializerOptions{WriteIndented=true}));
        }
    }
    
    // Also print status
    if (doc.RootElement.TryGetProperty("Status", out var status))
        Console.WriteLine($"\nStatus: {status}");
}
