using CsvHelper.Configuration;

namespace Farrellsoft.Example.SurveyDataLoad.Models;

public class RnpsSurveyResultMap : ClassMap<RnpsSurveyResult>
{
    public RnpsSurveyResultMap()
    {
        Map(m => m.Age).Name("age");
        Map(m => m.PartnerId).Name("nps_bpartner_id");
        Map(m => m.Name).Name("name").Convert(row =>
        {
            var value = row.Row.GetField("name");
            return value == "null" ? string.Empty : value ?? string.Empty;
        });
        Map(m => m.IsLowIncome).Name("low_income").Convert(row => row.Row.GetField("low_income") == "1");
        Map(m => m.City).Name("city");
        Map(m => m.ZipCode).Name("zip_code");
        Map(m => m.ReliabilityRating).Name("reliability_driver");
        Map(m => m.ReliabilityComment).Name("reliability_open_end");
        Map(m => m.PriceRating).Name("price_driver");
        Map(m => m.PriceComment).Name("price_open_end");
        Map(m => m.TransparencyRating).Name("transparency_driver");
        Map(m => m.TransparencyComment).Name("transparency_open_end");
        Map(m => m.OverallRating).Name("nps_raw");
        Map(m => m.SurveyDate).Name("survey_date_gmt").Convert(row =>
        {
            var dateStr = row.Row.GetField("survey_date_gmt");
            if (string.IsNullOrEmpty(dateStr) || dateStr == "null")
                return DateTime.MinValue;
            var gmtDate = DateTime.SpecifyKind(DateTime.Parse(dateStr), DateTimeKind.Utc);
            var estDate = TimeZoneInfo.ConvertTimeFromUtc(gmtDate, TimeZoneInfo.FindSystemTimeZoneById("Eastern Standard Time"));
            return estDate.Date;
        });
        Map(m => m.SurveyMonth).Name("month_surveyed").Convert(row =>
        {
            var value = row.Row.GetField("month_surveyed");
            return value == "null" ? string.Empty : value ?? string.Empty;
        });
        Map(m => m.SurveyYear).Name("year_surveyed");
        Map(m => m.SurveySeason).Name("season").Convert(row =>
        {
            var value = row.Row.GetField("season");
            return value == "null" ? string.Empty : value ?? string.Empty;
        });
    }
}
