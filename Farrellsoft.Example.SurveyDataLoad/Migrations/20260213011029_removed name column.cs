using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Farrellsoft.Example.SurveyDataLoad.Migrations
{
    /// <inheritdoc />
    public partial class removednamecolumn : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Name",
                table: "RnpsSurveyRecords");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Name",
                table: "RnpsSurveyRecords",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }
    }
}
