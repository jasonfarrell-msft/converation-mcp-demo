using System.Text;

namespace Farrellsoft.Examples.SurveyDataMcp.Utilities;

public static class SqlDdlGenerator
{
    public static string GenerateCreateTableDdl<T>(string tableName) where T : class
    {
        var type = typeof(T);
        var properties = type.GetProperties();

        var ddl = new StringBuilder();
        ddl.AppendLine($"CREATE TABLE {tableName} (");

        var columnDefinitions = new List<string>();

        foreach (var property in properties)
        {
            var columnName = property.Name;
            var sqlType = MapCSharpTypeToSqlType(property.PropertyType);
            var nullable = IsNullable(property.PropertyType) ? "NULL" : "NOT NULL";

            columnDefinitions.Add($"    {columnName} {sqlType} {nullable}");
        }

        ddl.AppendLine(string.Join(",\n", columnDefinitions));
        ddl.Append(");");

        return ddl.ToString();
    }

    private static string MapCSharpTypeToSqlType(Type type)
    {
        var underlyingType = Nullable.GetUnderlyingType(type) ?? type;

        return underlyingType.Name switch
        {
            "String" => "NVARCHAR(MAX)",
            "Int32" => "INT",
            "Int64" => "BIGINT",
            "Decimal" => "DECIMAL(18,2)",
            "Double" => "FLOAT",
            "Boolean" => "BIT",
            "DateTime" => "DATETIME2",
            "DateOnly" => "DATE",
            "TimeOnly" => "TIME",
            "Guid" => "UNIQUEIDENTIFIER",
            _ => "NVARCHAR(MAX)"
        };
    }

    private static bool IsNullable(Type type)
    {
        if (!type.IsValueType) return true; // Reference types are nullable by default
        return Nullable.GetUnderlyingType(type) != null;
    }
}
