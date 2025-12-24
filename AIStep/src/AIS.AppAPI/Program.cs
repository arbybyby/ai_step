using AIS.Database;
using AIS.Database.Repositories;
using AIS.Database.Services;
using AIS.Domain.Repositories;
using AIS.Domain.Services;

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

using System.Text;
using System.Security.Cryptography.X509Certificates;
using System.IO;

var builder = WebApplication.CreateBuilder(args);

// Try to read certificate configuration
var certPath = builder.Configuration["Kestrel:Certificates:Default:Path"]
    ?? builder.Configuration["ASPNETCORE_Kestrel__Certificates__Default__Path"];
var certPassword = builder.Configuration["Kestrel:Certificates:Default:Password"]
    ?? builder.Configuration["ASPNETCORE_Kestrel__Certificates__Default__Password"];

// Настройка Kestrel для HTTP и HTTPS
builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(80); // HTTP
    options.ListenAnyIP(443, listenOptions =>
    {
        if (!string.IsNullOrEmpty(certPath) && File.Exists(certPath))
        {
            try
            {
                var certBytes = File.ReadAllBytes(certPath);
                var cert = string.IsNullOrEmpty(certPassword)
                    ? new X509Certificate2(certBytes)
                    : new X509Certificate2(certBytes, certPassword);

                listenOptions.UseHttps(cert);
            }
            catch (Exception ex) when (ex is IOException || ex is UnauthorizedAccessException || ex is System.Security.Cryptography.CryptographicException)
            {
                Console.WriteLine($"Failed to load certificate at '{certPath}': {ex.Message}. Falling back to default HTTPS configuration.");
                listenOptions.UseHttps();
            }
        }
        else
        {
            Console.WriteLine("Certificate path not configured or file not found. Using default HTTPS configuration.");
            listenOptions.UseHttps();
        }
    });
});

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterPolicy",
        policy =>
        {
            policy.SetIsOriginAllowed(origin => true)
                .AllowAnyMethod()
                .AllowAnyHeader()
                .AllowCredentials();
        });
});

// Конфигурация базы данных
builder.Services.AddDbContext<AppDBContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("SQLite")));

// Регистрация репозиториев
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IStepsRepository, StepsRepository>();
builder.Services.AddScoped<IVerificationCodeRepository, VerificationCodeRepository>();
builder.Services.AddScoped<IRefreshTokenRepository, RefreshTokenRepository>();

// Регистрация сервисов
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<IJwtService, JwtService>();

// Register domain service required by StepsController
builder.Services.AddScoped<StepsService>();

// Настройка JWT аутентификации
var jwtSecret = builder.Configuration["Jwt:Secret"]
    ?? throw new InvalidOperationException("Jwt:Secret не настроен");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
        ValidateIssuer = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidateAudience = true,
        ValidAudience = builder.Configuration["Jwt:Audience"],
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();

// Add services to the container.
builder.Services.AddControllers();

// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("AllowFlutterPolicy");

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
