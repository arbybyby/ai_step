# Настройка HTTPS для разработки в Docker

## Быстрый старт

### 1. Сгенерируйте dev сертификат

В PowerShell выполните:

```powershell
.\generate-dev-cert.ps1
```

Или вручную:

```powershell
dotnet dev-certs https --clean
dotnet dev-certs https -ep $env:APPDATA\ASP.NET\Https\aspnetapp.pfx -p ""
dotnet dev-certs https --trust
```

### 2. Запустите Docker контейнеры

```powershell
docker-compose down
docker-compose up --build
```

## Доступ к приложению

- HTTP: http://localhost:8080 (автоматически перенаправляется на HTTPS)
- HTTPS: https://localhost:8081
- MailHog UI: http://localhost:8025

## Порты

- `8080` - HTTP (перенаправление на HTTPS)
- `8081` - HTTPS
- `1025` - SMTP (MailHog)
- `8025` - MailHog Web UI

## Как это работает

### Конфигурация портов

Kestrel настраивается через `appsettings.Development.json`:

```json
{
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://*:8080"
      },
      "Https": {
        "Url": "https://*:8081",
        "Certificate": {
          "Path": "/https/aspnetapp.pfx",
          "Password": ""
        }
      }
    }
  }
}
```

Это избегает конфликтов с переменными окружения и предупреждений "Overriding address(es)".

### Сертификат

- Windows: `%APPDATA%\ASP.NET\Https\aspnetapp.pfx`
- Linux/macOS: `~/.aspnet/https/aspnetapp.pfx`

Сертификат монтируется в контейнер по пути `/https/aspnetapp.pfx`.

## Преимущества этого подхода

✅ **Нет предупреждений** - единственный источник конфигурации  
✅ **Чистая конфигурация** - всё в одном файле `appsettings.Development.json`  
✅ **Нет переменных окружения** для портов  
✅ **Явная конфигурация** - видно все настройки в одном месте  

## Troubleshooting

### Ошибка: "Could not find file '/https/aspnetapp.pfx'"

Запустите скрипт `generate-dev-cert.ps1` для создания сертификата.

### Ошибка: "Certificate is not trusted"

В браузере это нормально для dev сертификата. Можно добавить исключение или выполнить:

```powershell
dotnet dev-certs https --trust
```

### Для Linux/macOS

```bash
dotnet dev-certs https --clean
dotnet dev-certs https -ep ~/.aspnet/https/aspnetapp.pfx -p ""
dotnet dev-certs https --trust
```

Volume в `docker-compose.yml` уже настроен для Linux/macOS: `~/.aspnet/https:/https:ro`

## Структура конфигурации

### appsettings.Development.json
- **Главный источник** конфигурации Kestrel
- Определяет HTTP/HTTPS endpoints и сертификат
- Используется автоматически когда `ASPNETCORE_ENVIRONMENT=Development`

### docker-compose.yml
- Минимальная конфигурация без портов Kestrel
- Только Email и ASPNETCORE_ENVIRONMENT
- Volumes для сертификата

### docker-compose.override.yml  
- Специфичная конфигурация для Visual Studio
- Добавляет UserSecrets для local development
- Переопределяет пути к сертификату для Windows

## Альтернативные подходы

### Вариант 1: Конфигурация в Program.cs (если нужен полный контроль)

```csharp
builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(8080); // HTTP
    options.ListenAnyIP(8081, listenOptions =>
    {
        listenOptions.UseHttps("/https/aspnetapp.pfx", "");
    });
});
```

### Вариант 2: Environment Variables (предыдущий подход)

```yaml
environment:
  - ASPNETCORE_URLS=https://+:8081;http://+:8080
  - ASPNETCORE_Kestrel__Certificates__Default__Path=/https/aspnetapp.pfx
```

**Текущий подход (appsettings.json) - рекомендуемый**, так как он:
- Не требует изменений кода
- Избегает конфликтов конфигурации
- Легко переключаться между окружениями
- Не засоряет переменные окружения
