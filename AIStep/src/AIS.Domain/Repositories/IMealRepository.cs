using AIS.Domain.Models;

namespace AIS.Domain.Repositories;

public interface IMealRepository
{
    Task<List<Meal?>> GetAll(int userID);

    Task<Meal?> Get(int mealID);

    Task Add(Meal meal);

    Task Remove(int mealId);
}
