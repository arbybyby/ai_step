namespace AIS.Domain.Models;

public class User
{
    public int ID { get; set; }

    public string Email { get; set; } = string.Empty;

    public string FirstName { get; set; } = string.Empty;

    public string LastName { get; set; } = string.Empty;

    public bool IsVerified { get; set; }

    public DateTime CreatedAt { get; set; }
}
