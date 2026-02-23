using System.Text;

using AIS.AppAPI.Extensions;
using AIS.AppAPI.Workers;
using AIS.Domain.Factories;
using AIS.Infrastructure;
using AIS.Infrastructure.Repositories;
using AIS.Infrastructure.Services;
using AIS.Domain.Repositories;
using AIS.Domain.Services;
using AIS.Infrastructure.RabbitMQ;

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// Улучшенное логирование для Docker
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

if (builder.Environment.IsDevelopment() || builder.Environment.EnvironmentName == "Docker")
{
    builder.Logging.SetMinimumLevel(LogLevel.Information);
}

var logger = LoggerFactory.Create(config => config.AddConsole()).CreateLogger("Startup");

logger.LogInformation("Starting application in {Environment} environment", builder.Environment.EnvironmentName);

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

builder.Services.AddMediatR(cfg =>
{
    cfg.RegisterServicesFromAssembly(typeof(Program).Assembly);
});

builder.Services.AddSingleton<RabbitConsumer>();
builder.Services.AddChannelMessage();

// Регистрация DbContext как Scoped (важно для избежания проблем с многопоточностью)
builder.Services.AddScoped<AppDBContext>();

// Регистрация репозиториев как Scoped (они зависят от DbContext)
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IStepsRepository, StepsRepository>();
builder.Services.AddScoped<IWaterTrackerRepository, WaterTrackingRepository>();
builder.Services.AddScoped<IVerificationCodeRepository, VerificationCodeRepository>();
builder.Services.AddScoped<IRefreshTokenRepository, RefreshTokenRepository>();
builder.Services.AddScoped<IUserMealRepository, UserMealRepository>();
builder.Services.AddScoped<IMealRepository, MealRepository>();
builder.Services.AddScoped<IAvatarRepository, AvatarRepository>();

// Factories - также Scoped, так как зависят от репозиториев
builder.Services.AddScoped<UserMealFactory>();
builder.Services.AddHostedService<MealConsumerWorker>();

// Регистрация сервисов как Scoped (они зависят от репозиториев)
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<WaterTrackerService>();
builder.Services.AddScoped<StepsService>();
builder.Services.AddScoped<IJwtService, JwtService>();  // Зависит от IRefreshTokenRepository и IUserRepository

// Эти сервисы могут оставаться Singleton, так как не зависят от DbContext
builder.Services.AddSingleton<IEmailService, EmailService>();

// Настройка JWT аутентификации
var jwtSecret = builder.Configuration["Jwt:Secret"];
var jwtIssuer = builder.Configuration["Jwt:Issuer"];
var jwtAudience = builder.Configuration["Jwt:Audience"];

logger.LogInformation("JWT Configuration - Issuer: {Issuer}, Audience: {Audience}, Secret Length: {SecretLength}",
    jwtIssuer, jwtAudience, jwtSecret?.Length ?? 0);

if (string.IsNullOrEmpty(jwtSecret))
{
    throw new InvalidOperationException("Jwt:Secret не настроен");
}

if (string.IsNullOrEmpty(jwtIssuer))
{
    throw new InvalidOperationException("Jwt:Issuer не настроен");
}

if (string.IsNullOrEmpty(jwtAudience))
{
    throw new InvalidOperationException("Jwt:Audience не настроен");
}

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
        ValidIssuer = jwtIssuer,
        ValidateAudience = true,
        ValidAudience = jwtAudience,
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };

    // Добавляем логирование для отладки
    options.Events = new JwtBearerEvents
    {
        OnAuthenticationFailed = context =>
        {
            var contextLogger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
            contextLogger.LogError("Authentication failed: {Message}", context.Exception.Message);
            return Task.CompletedTask;
        },
        OnTokenValidated = context =>
        {
            var contextLogger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
            contextLogger.LogInformation("Token validated for user: {User}", context.Principal?.Identity?.Name);
            return Task.CompletedTask;
        },
        OnChallenge = context =>
        {
            var contextLogger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
            contextLogger.LogWarning("Authentication challenge: {Error}, {ErrorDescription}",
                context.Error, context.ErrorDescription);
            return Task.CompletedTask;
        },
        OnMessageReceived = context =>
        {
            var contextLogger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
            var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Split(" ").Last();
            contextLogger.LogDebug("Token received: {HasToken}", !string.IsNullOrEmpty(token));
            return Task.CompletedTask;
        }
    };
});

builder.Services.AddAuthorization();

// Add services to the container.
builder.Services.AddControllers();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowFlutterPolicy");

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

logger.LogInformation("Application configured successfully");

app.Run();
