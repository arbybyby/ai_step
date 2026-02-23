using AIS.Domain.Models;

namespace AIS.Infrastructure.Entities;

public class MealEntity
{
    public int Id { get; set; }

    public string MealName { get; set; } = string.Empty;

    public MealType MealType { get; set; }

    public float Calories { get; set; }

    public float Protein { get; set; }

    public float Carbs { get; set; }

    public float Fat { get; set; }
}
