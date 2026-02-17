using AIS.Domain.Models;
using AIS.Domain.Repositories;

namespace AIS.Domain.Factories;

public class UserMealFactory
{
    private readonly IMealRepository _mealRepository;

    public UserMealFactory(IMealRepository mealRepository)
    {
        _mealRepository = mealRepository;
    }

    public async Task<UserMeal> Create(int userID, int mealID, string typeOfMeal, float grammes, DateTime date)
    {
        Meal meal = await _mealRepository.Get(mealID);
        Enum.TryParse(typeOfMeal, out MealType mealType);

        return new UserMeal()
        {
            UserID = userID,
            MealName = meal.MealName,
            MealID = mealID,
            Grammes = grammes,
            MealType = mealType,
            Calories = (meal.Calories * grammes) / 100.0f,
            Fat = (meal.Fat * grammes) / 100.0f,
            Protein = (meal.Protein * grammes) / 100.0f,
            Carbs = (meal.Carbs * grammes) / 100.0f,
        };
    }
}
