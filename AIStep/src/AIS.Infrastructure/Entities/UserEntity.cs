using System.ComponentModel.DataAnnotations;

using AIS.Domain.Models;

namespace AIS.Infrastructure.Entities;

public class UserEntity
{
    [Key]
    public int ID { get; set; }

    public string Email { get; set; } = null!;

    public string FirstName { get; set; } = null!;

    public string LastName { get; set; } = null!;

    public string PasswordHash { get; set; } = null!;

    public int Age { get; set; }

    public Gender Gender { get; set; }

    public ActivityLevel  ActivityLevel { get; set; }

    public FitnessGoal FitnessGoal { get; set; }

    public double HeightCm { get; set; }

    public double WeightKg { get; set; }

    public bool IsVerified { get; set; }

    public DateTime CreatedAt { get; set; }
}
