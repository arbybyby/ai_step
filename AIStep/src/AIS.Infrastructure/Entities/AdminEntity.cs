using System.ComponentModel.DataAnnotations;

namespace AIS.Infrastructure.Entities;

public class AdminEntity
{
    [Key]
    public int ID { get; set; }

    public string Email { get; set; } = null!;

    public string FirstName { get; set; } = null!;

    public string LastName { get; set; } = null!;

    public string PasswordHash { get; set; } = null!;

    public DateTime CreatedAt { get; set; }
}

