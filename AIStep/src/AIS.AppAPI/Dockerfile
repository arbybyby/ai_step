# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

# This stage is used when running from VS in fast mode (Default for Debug configuration)
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER $APP_UID
WORKDIR /app
EXPOSE 5050
EXPOSE 5051


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
ENTRYPOINT ["dotnet", "AIS.AppAPI.dll"]
