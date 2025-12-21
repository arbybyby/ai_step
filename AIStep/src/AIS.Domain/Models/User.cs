namespace AIS.Domain.Models;

public class User
{
    public int ID { get; set; }

    public string Email { get; set; } = string.Empty;

    public string FirstName { get; set; } = string.Empty;

    public string LastName { get; set; } = string.Empty;

    public double HeightCm { get; set; }

    public double WeightKg { get; set; }

    public bool IsVerified { get; set; }

    public DateTime CreatedAt { get; set; }
}
