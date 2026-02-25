using AIS.Domain.Models;
using System.ComponentModel.DataAnnotations;

namespace AIS.AdminPanel.Models;

public class UserEditRequest
{
    [Required(ErrorMessage = "Email обязателен")]
    [EmailAddress(ErrorMessage = "Неверный формат email")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Имя обязательно")]
    public string FirstName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Фамилия обязательна")]
    public string LastName { get; set; } = string.Empty;

    [Range(1, 150, ErrorMessage = "Возраст должен быть от 1 до 150")]
    public int Age { get; set; }

    public Gender Gender { get; set; }

    public ActivityLevel ActivityLevel { get; set; }

    public FitnessGoal FitnessGoal { get; set; }

    [Range(0, 300, ErrorMessage = "Рост должен быть от 0 до 300")]
    public double HeightCm { get; set; }

    [Range(0, 500, ErrorMessage = "Вес должен быть от 0 до 500")]
    public double WeightKg { get; set; }

    public bool IsVerified { get; set; }
}

