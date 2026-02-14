using AIS.Domain.Models;

namespace AIS.Domain.Repositories;

public interface IUserMealRepository
{
    Task<List<UserMeal?>> GetAll(int userID);

    Task<UserMeal?> Get(int mealID);

    Task Add(UserMeal userMeal);

    Task Remove(int mealId);
}
