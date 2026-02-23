using System.ComponentModel.DataAnnotations;

namespace AIS.Infrastructure.Entities;

public class VerificationCodeEntity
{
    [Key]
    public int ID { get; set; }

    public string Email { get; set; } = null!;

    public string Code { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime ExpiresAt { get; set; }

    public bool IsUsed { get; set; }
}
