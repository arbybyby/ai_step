using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Infrastructure.Entities;

using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AIS.Infrastructure.Repositories;

public class UserMealRepository : IUserMealRepository
{
    private readonly AppDBContext _context;
    private readonly ILogger<UserMealRepository> _logger;

    public UserMealRepository(AppDBContext context, ILogger<UserMealRepository> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<List<UserMeal?>> GetAll(int userID)
    {
        List<UserMealEntity> entities = await _context.UserMeals
            .Where(m => m.UserID == userID)
            .ToListAsync();

        List<UserMeal?> result = entities.Select(MapToDomain).ToList();

        return result;
    }

    public async Task<UserMeal?> Get(int mealID)
    {
        UserMealEntity? entity = await _context.UserMeals.FindAsync(mealID);
        return entity == null ? null : MapToDomain(entity);
    }

    public async Task Add(UserMeal userMeal)
    {
        _logger.LogInformation("Adding meal with ID {MealID} for user {UserID}", userMeal.Id, userMeal.UserID);
        UserMealEntity entity = MapToEntity(userMeal);
        await _context.AddAsync(entity);
        await _context.SaveChangesAsync();
    }

    public async Task Remove(int mealId)
    {
        await _context.UserMeals.Where(m => m.Id == mealId).ExecuteDeleteAsync();
        await _context.SaveChangesAsync();
    }

    private UserMealEntity MapToEntity(UserMeal userMeal)
    {
        return new UserMealEntity
        {
            Id = userMeal.Id,
            UserID =  userMeal.UserID,
            Calories = userMeal.Calories,
            Protein = userMeal.Protein,
            Carbs = userMeal.Carbs,
            Fat = userMeal.Fat,
            Grammes = userMeal.Grammes,
            MealName = userMeal.MealName,
            MealType = userMeal.MealType
        };
    }

    private UserMeal? MapToDomain(UserMealEntity? meal)
    {
        if (meal == null)
        {
            return null;
        }

        return new UserMeal
        {
            Id = meal.Id,
            UserID =  meal.UserID,
            Calories = meal.Calories,
            Protein = meal.Protein,
            Carbs = meal.Carbs,
            Fat = meal.Fat,
            Grammes = meal.Grammes,
            MealName = meal.MealName,
            MealType = meal.MealType
        };
    }
}
