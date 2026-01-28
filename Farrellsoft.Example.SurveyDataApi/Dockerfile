# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY Farrellsoft.Example.SurveyDataApi.csproj .
RUN dotnet restore

# Copy everything else and build
COPY . .
RUN dotnet build "Farrellsoft.Example.SurveyDataApi.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "Farrellsoft.Example.SurveyDataApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# Copy published app
COPY --from=publish /app/publish .

# Set environment variables
ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "Farrellsoft.Example.SurveyDataApi.dll"]
