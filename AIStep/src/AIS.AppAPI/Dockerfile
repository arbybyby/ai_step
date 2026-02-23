# --- ЭТАП 1: Runtime (Base) ---
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER root
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# --- ЭТАП 2: Сборка (Build) ---
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# ИСПРАВЛЕНО: Убраны --clean и --trust. Оставляем только генерацию файла.
RUN mkdir -p /app/https && \
    dotnet dev-certs https -ep /app/https/aspnetapp.pfx -p DevCertPassword

# Копирование проектов
COPY ["src/AIS.AppAPI/AIS.AppAPI.csproj", "src/AIS.AppAPI/"]
COPY ["src/AIS.Domain/AIS.Domain.csproj", "src/AIS.Domain/"]
COPY ["src/AIS.Infrastructure/AIS.Infrastructure.csproj", "src/AIS.Infrastructure/"]

RUN dotnet restore "./src/AIS.AppAPI/AIS.AppAPI.csproj"

# Копирование кода и сборка
COPY . .
WORKDIR "/src/src/AIS.AppAPI"
RUN dotnet build "./AIS.AppAPI.csproj" -c $BUILD_CONFIGURATION -o /app/build --no-restore

# --- ЭТАП 3: Публикация ---
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./AIS.AppAPI.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# --- ЭТАП 4: Финальный образ (Final) ---
FROM base AS final
WORKDIR /app

# Установка dos2unix
RUN apt-get update && apt-get install -y dos2unix && rm -rf /var/lib/apt/lists/*

# Копируем результаты
COPY --from=publish /app/publish .
COPY --from=build /app/https /app/https
COPY --from=build /src/src/AIS.AppAPI/docker-entrypoint.sh ./

# Исправление прав и форматов
RUN dos2unix ./docker-entrypoint.sh && \
    chmod +x ./docker-entrypoint.sh && \
    mkdir -p /app/data && \
    chown -R 1000:1000 /app /app/data /app/https

USER 1000
ENTRYPOINT ["./docker-entrypoint.sh"]
