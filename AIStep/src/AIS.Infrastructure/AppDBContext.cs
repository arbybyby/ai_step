﻿using AIS.Infrastructure.Configurations;
using AIS.Infrastructure.Entities;

using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace AIS.Infrastructure;

public class AppDBContext : DbContext
{
    private readonly IConfiguration _configuration;

    public AppDBContext(IConfiguration configuration)
    {
        _configuration = configuration;
        Database.EnsureCreated();
    }

    public DbSet<UserEntity> Users { get; set; }

    public DbSet<AdminEntity> Admins { get; set; }

    public DbSet<VerificationCodeEntity> VerificationCodes { get; set; }

    public DbSet<RefreshTokenEntity> RefreshTokens { get; set; }

    public DbSet<DayStepsInfoEntity> DayStepsInfos { get; set; }

    public DbSet<WaterInfoEntity> WaterInfos { get; set; }

    public DbSet<UserMealEntity> UserMeals { get; set; }

    public DbSet<MealEntity> Meals { get; set; }

    public DbSet<AvatarURLEntity> AvatarURLs { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfiguration(new UserConfiguration());
        modelBuilder.ApplyConfiguration(new AdminConfiguration());
        modelBuilder.ApplyConfiguration(new VerificationCodeConfiguration());
        modelBuilder.ApplyConfiguration(new RefreshTokenConfiguration());

        base.OnModelCreating(modelBuilder);
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        optionsBuilder.UseNpgsql(_configuration.GetConnectionString("PSQL"));

        base.OnConfiguring(optionsBuilder);
    }
}
