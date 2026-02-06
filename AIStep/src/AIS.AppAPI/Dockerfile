# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

# This stage is used when running from VS in fast mode (Default for Debug configuration)
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER root
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# This stage is used to build the service project
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Генерируем dev-сертификат для HTTPS (требует SDK)
RUN mkdir -p /app/https && \
    dotnet dev-certs https --clean && \
    dotnet dev-certs https -ep /app/https/aspnetapp.pfx -p DevCertPassword && \
    dotnet dev-certs https --trust
COPY ["src/AIS.AppAPI/AIS.AppAPI.csproj", "src/AIS.AppAPI/"]
COPY ["src/AIS.Domain/AIS.Domain.csproj", "src/AIS.Domain/"]
COPY ["src/AIS.Infrastructure/AIS.Infrastructure.csproj", "src/AIS.Infrastructure/"]
RUN dotnet restore "./src/AIS.AppAPI/AIS.AppAPI.csproj"
COPY . .
WORKDIR "/src/src/AIS.AppAPI"
RUN dotnet build "./AIS.AppAPI.csproj" -c $BUILD_CONFIGURATION -o /app/build --no-restore

# This stage is used to publish the service project to be copied to the final stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./AIS.AppAPI.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# This stage is used in production or when running from VS in regular mode (Default when not using the Debug configuration)
FROM base AS final
WORKDIR /app

# Install dos2unix for line ending conversion
RUN apt-get update && apt-get install -y dos2unix && rm -rf /var/lib/apt/lists/*

COPY --from=publish /app/publish .
COPY --from=build /app/https /app/https
COPY --from=build /src/src/AIS.AppAPI/docker-entrypoint.sh ./

# Fix line endings (CRLF -> LF) and set permissions
RUN dos2unix ./docker-entrypoint.sh && \
    chmod +x ./docker-entrypoint.sh && \
    ls -la ./docker-entrypoint.sh && \
    mkdir -p /app/data && \
    chown -R 1000:1000 /app /app/data /app/https

USER 1000
ENTRYPOINT ["./docker-entrypoint.sh"]
