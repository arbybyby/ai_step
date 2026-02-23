using AIS.Infrastructure.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AIS.Infrastructure.Configurations;

public class AdminConfiguration : IEntityTypeConfiguration<AdminEntity>
{
    public void Configure(EntityTypeBuilder<AdminEntity> builder)
    {
        builder.ToTable("admins");

        builder.HasKey(e => e.ID);

        builder.HasIndex(e => e.Email)
               .IsUnique();

        builder.Property(e => e.CreatedAt)
               .HasDefaultValueSql("NOW()");
    }
}

