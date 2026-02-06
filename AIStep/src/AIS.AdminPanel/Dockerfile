FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER root
WORKDIR /app
EXPOSE 8000
EXPOSE 8001

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Генерируем dev-сертификат для HTTPS (требует SDK)
RUN mkdir -p /app/https && \
    dotnet dev-certs https --clean && \
    dotnet dev-certs https -ep /app/https/aspnetapp.pfx -p DevCertPassword && \
    dotnet dev-certs https --trust

COPY ["src/AIS.AdminPanel/AIS.AdminPanel.csproj", "src/AIS.AdminPanel/"]
RUN dotnet restore "src/AIS.AdminPanel/AIS.AdminPanel.csproj"
COPY . .
WORKDIR "/src/src/AIS.AdminPanel"
RUN dotnet build "./AIS.AdminPanel.csproj" -c $BUILD_CONFIGURATION -o /app/build --no-restore

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./AIS.AdminPanel.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app

# Install dos2unix for line ending conversion
RUN apt-get update && apt-get install -y dos2unix && rm -rf /var/lib/apt/lists/*

COPY --from=publish /app/publish .
COPY --from=build /app/https /app/https
COPY --from=build /src/src/AIS.AdminPanel/docker-entrypoint.sh ./

# Fix line endings (CRLF -> LF) and set permissions
RUN dos2unix ./docker-entrypoint.sh && \
    chmod +x ./docker-entrypoint.sh && \
    ls -la ./docker-entrypoint.sh && \
    mkdir -p /app/data && \
    chown -R 1000:1000 /app /app/data /app/https

USER 1000

ENTRYPOINT ["./docker-entrypoint.sh"]
