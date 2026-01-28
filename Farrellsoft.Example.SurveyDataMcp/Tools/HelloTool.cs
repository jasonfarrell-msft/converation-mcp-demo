using ModelContextProtocol.Server;
using System.ComponentModel;

namespace Farrellsoft.Example.SurveyDataMcp.Tools;

[McpServerToolType]
public static class HelloTool
{
    [McpServerTool, Description("Greets a person by name")]
    public static string SayHello(
        [Description("The name of the person to greet")] string name)
    {
        return $"Hello {name}";
    }
}
