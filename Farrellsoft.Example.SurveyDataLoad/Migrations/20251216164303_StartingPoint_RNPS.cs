using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Farrellsoft.Example.SurveyDataLoad.Migrations
{
    /// <inheritdoc />
    public partial class StartingPoint_RNPS : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "RnpsSurveyRecords",
                columns: table => new
                {
                    RecordId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Age = table.Column<short>(type: "smallint", nullable: true),
                    PartnerId = table.Column<long>(type: "bigint", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IsLowIncome = table.Column<bool>(type: "bit", nullable: false),
                    City = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ZipCode = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ReliabilityRating = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ReliabilityComment = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PriceRating = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PriceComment = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    TransparencyRating = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    TransparencyComment = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    OverallRating = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    SurveyDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    SurveyMonth = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    SurveyYear = table.Column<short>(type: "smallint", nullable: false),
                    SurveySeason = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RnpsSurveyRecords", x => x.RecordId);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RnpsSurveyRecords");
        }
    }
}
