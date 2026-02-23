using AIS.Infrastructure.Entities;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AIS.Infrastructure.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<UserEntity>
{
    public void Configure(EntityTypeBuilder<UserEntity> builder)
    {
        builder.HasKey(e => e.ID);

        builder.HasIndex(e => e.Email)
               .IsUnique();

        builder.Property(e => e.CreatedAt)
               .HasDefaultValueSql("NOW()");
    }
}
