namespace AIS.Domain.Models;

public class Meal
{
    public int Id { get; set; }

    public int UserID { get; set; }

    public MealType MealType { get; set; }
}

public enum MealType
{
    Breakfast,
    Lunch,
    Dinner,
}
