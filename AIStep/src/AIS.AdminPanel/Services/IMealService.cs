using AIS.Domain.Models;

namespace AIS.AdminPanel.Services;

public interface IMealService
{
    Task<List<Meal>> GetAllMealsAsync();

    Task<Meal> GetMealAsync(int id);

    Task<Meal> CreateMealAsync(Meal meal);

    Task UpdateMealAsync(int id, Meal meal);

    Task DeleteMealAsync(int id);
}

