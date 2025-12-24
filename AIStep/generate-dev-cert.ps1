# Скрипт для генерации dev сертификата для Docker

Write-Host "Генерация dev сертификата для ASP.NET Core..." -ForegroundColor Green

# Очистка старых сертификатов
dotnet dev-certs https --clean

# Генерация нового сертификата
dotnet dev-certs https -ep $env:APPDATA\ASP.NET\Https\aspnetapp.pfx -p ""

# Доверие сертификату (только для Windows/macOS)
dotnet dev-certs https --trust

Write-Host "Сертификат успешно создан!" -ForegroundColor Green
Write-Host "Путь: $env:APPDATA\ASP.NET\Https\aspnetapp.pfx" -ForegroundColor Yellow
Write-Host ""
Write-Host "Теперь можно запустить: docker-compose up --build" -ForegroundColor Cyan
