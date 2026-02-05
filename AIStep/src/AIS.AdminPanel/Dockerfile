FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER $APP_UID
WORKDIR /app
EXPOSE 8000
EXPOSE 8001

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["src/AIS.AdminPanel/AIS.AdminPanel.csproj", "src/AIS.AdminPanel/"]
RUN dotnet restore "src/AIS.AdminPanel/AIS.AdminPanel.csproj"
COPY . .
WORKDIR "/src/src/AIS.AdminPanel"
RUN dotnet build "./AIS.AdminPanel.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./AIS.AdminPanel.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "AIS.AdminPanel.dll"]
