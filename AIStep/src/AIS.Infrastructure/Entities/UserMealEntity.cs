using AIS.Domain.Models;

namespace AIS.Infrastructure.Entities;

public class UserMealEntity
{
    public int Id { get; set; }

    public int UserID { get; set; }

    public string MealName { get; set; } = null!;

    public MealType MealType { get; set; }

    public float Grammes { get; set; }

    public float Calories { get; set; }

    public float Protein { get; set; }

    public float Carbs { get; set; }

    public float Fat { get; set; }
}
