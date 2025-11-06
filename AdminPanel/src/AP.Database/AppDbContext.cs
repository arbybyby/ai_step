using AP.Database.Models;
using Microsoft.EntityFrameworkCore;

namespace AP.Database;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<UserEntity> Users { get; set; } = null!;

    public DbSet<StepsEntity> Steps { get; set; } = null!;
}
