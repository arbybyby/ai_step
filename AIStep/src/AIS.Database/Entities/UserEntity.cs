using System.ComponentModel.DataAnnotations;

namespace AIS.Database.Entities;

public class UserEntity
{
    [Key]
    public int ID { get; set; }

    public string Email { get; set; } = null!;

    public string FirstName { get; set; } = null!;

    public string LastName { get; set; } = null!;

    public string PasswordHash { get; set; } = null!;

    public bool IsVerified { get; set; }

    public DateTime CreatedAt { get; set; }
}
