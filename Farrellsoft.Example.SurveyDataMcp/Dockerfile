# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["Farrellsoft.Example.SurveyDataMcp.csproj", "./"]
RUN dotnet restore "Farrellsoft.Example.SurveyDataMcp.csproj"

# Copy source code and build
COPY . .
RUN dotnet build "Farrellsoft.Example.SurveyDataMcp.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "Farrellsoft.Example.SurveyDataMcp.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
EXPOSE 8080

# Copy published app
COPY --from=publish /app/publish .

# Set environment variables for Azure Container Apps
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

CMD ["dotnet", "Farrellsoft.Example.SurveyDataMcp.dll"]
