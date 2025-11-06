using AP.Domain;
using System.ComponentModel.DataAnnotations.Schema;

namespace AP.Database.Models;

[Table("users")]
public class UserEntity
{
    [Column("id")]
    public long Id { get; set; }

    [Column("email")]
    public string Email { get; set; } = string.Empty;

    [Column("first_name")]
    public string FirstName { get; set; } = string.Empty;

    [Column("last_name")]
    public string LastName { get; set; } = string.Empty;

    [Column("created_at")]
    public DateTime? CreatedAt { get; set; }

    [Column("updated_at")]
    public DateTime? UpdatedAt { get; set; }

    [Column("last_login_at")]
    public DateTime? LastLoginAt { get; set; }

    public User ToDomain()
    {
        return new User
        {
            Id = Id,
            Email = Email,
            FirstName = FirstName,
            LastName = LastName,
            CreatedAt = CreatedAt,
            UpdatedAt = UpdatedAt,
            LastLoginAt = LastLoginAt
        };
    }
}
