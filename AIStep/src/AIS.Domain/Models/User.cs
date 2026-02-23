namespace AIS.Domain.Models;

public class User
{
    public int ID { get; set; }

    public string Email { get; set; } = string.Empty;

    public string FirstName { get; set; } = string.Empty;

    public string LastName { get; set; } = string.Empty;

    public int Age { get; set; }

    public Gender Gender { get; set; }

    public ActivityLevel ActivityLevel { get; set; }

    public FitnessGoal FitnessGoal { get; set; }

    public double HeightCm { get; set; }

    public double WeightKg { get; set; }

    public bool IsVerified { get; set; }

    public DateTime CreatedAt { get; set; }
}

public enum Gender
{
    None,
    Male,
    Female,
    Other,
}

public enum ActivityLevel
{
    Sedentary,
    Light,
    Moderate,
    Active,
    VeryActive,
}

public enum FitnessGoal
{
    LoseWeight,
    MaintainWeight,
    GainMuscle
}
