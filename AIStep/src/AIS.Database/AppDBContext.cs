using AIS.Database.Entities;
using Microsoft.EntityFrameworkCore;

namespace AIS.Database;

public class AppDBContext : DbContext
{
    public AppDBContext(DbContextOptions<AppDBContext> options) : base(options)
    {
    }

    public DbSet<UserEntity> Users { get; set; }
    
    public DbSet<VerificationCodeEntity> VerificationCodes { get; set; }

    public DbSet<RefreshTokenEntity> RefreshTokens { get; set; }

    public DbSet<DayStepsInfoEntity> DayStepsInfos { get; set; }

    public DbSet<WaterInfoEntity> WaterInfos { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<UserEntity>(entity =>
        {
            entity.HasIndex(e => e.Email).IsUnique();
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
        });

        modelBuilder.Entity<VerificationCodeEntity>(entity =>
        {
            entity.HasIndex(e => new { e.Email, e.Code });
        });

        modelBuilder.Entity<RefreshTokenEntity>(entity =>
        {
            entity.HasIndex(e => e.Token);
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
