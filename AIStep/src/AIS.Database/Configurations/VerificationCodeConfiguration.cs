using AIS.Database.Entities;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AIS.Database.Configurations;

public class VerificationCodeConfiguration : IEntityTypeConfiguration<VerificationCodeEntity>
{
    public void Configure(EntityTypeBuilder<VerificationCodeEntity> builder)
    {
        builder.HasIndex(e => new { e.Email, e.Code });
    }
}
