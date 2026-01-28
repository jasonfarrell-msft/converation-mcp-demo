using System.Text.Json;
using System.Text.Json.Serialization;
using Farrellsoft.Examples.SurveyDataMcp.Entities;

namespace Farrellsoft.Examples.SurveyDataMcp.Utilities;

public class SurveyRecordJsonConverter : JsonConverter<RpnsSurveyDataRecord>
{
    public override RpnsSurveyDataRecord Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        throw new NotImplementedException("Deserialization is not supported for this converter");
    }

    public override void Write(Utf8JsonWriter writer, RpnsSurveyDataRecord value, JsonSerializerOptions options)
    {
        writer.WriteStartObject();

        if (value.Age.HasValue)
        {
            writer.WritePropertyName("age");
            writer.WriteNumberValue(value.Age.Value);
        }

        if (!string.IsNullOrEmpty(value.Name))
            writer.WriteString("name", value.Name);

        if (value.IsLowIncome.HasValue)
            writer.WriteString("isLowIncome", value.IsLowIncome.Value ? "Yes" : "No");

        if (!string.IsNullOrEmpty(value.City))
            writer.WriteString("city", value.City);
        
        if (!string.IsNullOrEmpty(value.ZipCode))
            writer.WriteString("zipcode", value.ZipCode);

        if (value.ReliabilityRating.HasValue)
        {
            var sentiment = ConvertRatingToSentiment(value.ReliabilityRating);
            if (sentiment != "Unknown")
                writer.WriteString("reliability sentiment", sentiment);
        }
        
        if (!string.IsNullOrEmpty(value.ReliabilityComment))
            writer.WriteString("reliability comments", value.ReliabilityComment);

        if (value.PriceRating.HasValue)
        {
            var sentiment = ConvertRatingToSentiment(value.PriceRating);
            if (sentiment != "Unknown")
                writer.WriteString("price sentiment", sentiment);
        }
        
        if (!string.IsNullOrEmpty(value.PriceComment))
            writer.WriteString("price comments", value.PriceComment);

        if (value.TransparencyRating.HasValue)
        {
            var sentiment = ConvertRatingToSentiment(value.TransparencyRating);
            if (sentiment != "Unknown")
                writer.WriteString("transparency sentiment", sentiment);
        }
        
        if (!string.IsNullOrEmpty(value.TransparencyComment))
            writer.WriteString("transparency comments", value.TransparencyComment);

        if (value.OverallRating.HasValue)
        {
            var sentiment = ConvertRatingToSentiment(value.OverallRating);
            if (sentiment != "Unknown")
                writer.WriteString("overall sentiment", sentiment);
        }

        writer.WriteString("survey date", value.SurveyDate.ToString("yyyy-MM-dd"));
        
        if (!string.IsNullOrEmpty(value.SurveySeason))
            writer.WriteString("season", value.SurveySeason);
        
        if (!string.IsNullOrEmpty(value.SurveyMonth))
            writer.WriteString("survey month", value.SurveyMonth);
        
        if (value.SurveyYear.HasValue)
            writer.WriteNumber("survey year", value.SurveyYear.Value);

        writer.WriteEndObject();
    }

    private static string ConvertRatingToSentiment(short? rating)
    {
        return rating switch
        {
            1 => "Good",
            0 => "Neutral",
            -1 => "Negative",
            _ => "Unknown"
        };
    }
}
