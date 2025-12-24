# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

# This stage is used when running from VS in fast mode (Default for Debug configuration)
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER root
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# Install gosu for switching users in entrypoint
RUN apt-get update && apt-get install -y gosu && rm -rf /var/lib/apt/lists/*

# Создаём директории для HTTPS сертификата и DataProtection ключей
RUN mkdir -p /https && chmod 755 /https && \
    mkdir -p /app/DataProtection-Keys && \
    mkdir -p /app/data && \
    chown -R $APP_UID:$APP_UID /app/DataProtection-Keys && \
    chmod 700 /app/DataProtection-Keys

# Create entrypoint script inline to avoid line ending issues
RUN echo '#!/bin/bash' > /usr/local/bin/docker-entrypoint.sh && \
    echo 'set -e' >> /usr/local/bin/docker-entrypoint.sh && \
    echo 'if [ -d "/app/data" ]; then' >> /usr/local/bin/docker-entrypoint.sh && \
    echo '    echo "Fixing ownership of /app/data..."' >> /usr/local/bin/docker-entrypoint.sh && \
    echo '    chown -R $APP_UID:$APP_UID /app/data' >> /usr/local/bin/docker-entrypoint.sh && \
    echo '    chmod 755 /app/data' >> /usr/local/bin/docker-entrypoint.sh && \
    echo '    echo "Permissions fixed"' >> /usr/local/bin/docker-entrypoint.sh && \
    echo 'fi' >> /usr/local/bin/docker-entrypoint.sh && \
    echo 'exec gosu $APP_UID dotnet AIS.AppAPI.dll "$@"' >> /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# This stage is used to build the service project
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["src/AIS.AppAPI/AIS.AppAPI.csproj", "src/AIS.AppAPI/"]
COPY ["src/AIS.Domain/AIS.Domain.csproj", "src/AIS.Domain/"]
COPY ["src/AIS.Database/AIS.Database.csproj", "src/AIS.Database/"]
RUN dotnet restore "./src/AIS.AppAPI/AIS.AppAPI.csproj"
COPY . .
WORKDIR "/src/src/AIS.AppAPI"
RUN dotnet build "./AIS.AppAPI.csproj" -c $BUILD_CONFIGURATION -o /app/build

# This stage is used to publish the service project to be copied to the final stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./AIS.AppAPI.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# This stage is used in production or when running from VS in regular mode (Default when not using the Debug configuration)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
