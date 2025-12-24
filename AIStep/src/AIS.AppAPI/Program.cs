using System.Text;

using AIS.Database;
using AIS.Database.Repositories;
using AIS.Database.Services;
using AIS.Domain.Repositories;
using AIS.Domain.Services;

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// Настройка Data Protection для Docker
var keysDirectory = new DirectoryInfo("/app/DataProtection-Keys");
builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(keysDirectory)
    .SetApplicationName("AIS.AppAPI");

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

// Ensure database is created (creates SQLite file and tables if missing)
using (var scope = app.Services.CreateScope())
{
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    
    try
    {
        var sqliteConn = builder.Configuration.GetConnectionString("SQLite");
        if (!string.IsNullOrWhiteSpace(sqliteConn))
        {
            var sqliteBuilder = new SqliteConnectionStringBuilder(sqliteConn);
            var dataSource = sqliteBuilder.DataSource;
            
            if (!string.IsNullOrEmpty(dataSource))
            {
                logger.LogInformation("SQLite database path: {DataSource}", dataSource);
                
                var dir = Path.GetDirectoryName(dataSource);
                if (!string.IsNullOrEmpty(dir))
                {
                    if (!Directory.Exists(dir))
                    {
                        logger.LogInformation("Creating directory: {Directory}", dir);
                        Directory.CreateDirectory(dir);
                        logger.LogInformation("Directory created successfully");
                    }
                    else
                    {
                        logger.LogInformation("Directory already exists: {Directory}", dir);
                    }
                }
                
                // Verify directory is writable by attempting to create a test file
                var testFile = Path.Combine(dir ?? ".", ".write-test");
                try
                {
                    File.WriteAllText(testFile, "test");
                    File.Delete(testFile);
                    logger.LogInformation("Directory write test successful");
                }
                catch (Exception ex)
                {
                    logger.LogError(ex, "Directory is not writable. Check permissions for: {Directory}", dir);
                }
            }
        }
        
        logger.LogInformation("Ensuring database is created...");
        var db = scope.ServiceProvider.GetRequiredService<AppDBContext>();
        db.Database.EnsureCreated();
        logger.LogInformation("Database created successfully");
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to create database. Application will continue but database operations may fail.");
    }
}

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
