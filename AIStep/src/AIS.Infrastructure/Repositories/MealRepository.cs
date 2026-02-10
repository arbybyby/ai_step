using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Infrastructure.Entities;

using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AIS.Infrastructure.Repositories;

public class MealRepository : IMealRepository
{
    private readonly AppDBContext _context;
    private readonly ILogger<MealRepository> _logger;

    public MealRepository(AppDBContext context, ILogger<MealRepository> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<List<Meal?>> GetAll(int userID)
    {
        List<MealEntity> entities = await _context.Meals
            .Where(m => m.UserID == userID)
            .ToListAsync();

        List<Meal?> result = entities.Select(MapToDomain).ToList();

        return result;
    }

    public async Task<Meal?> Get(int mealID)
    {
        MealEntity? entity = await _context.Meals.FindAsync(mealID);
        return entity == null ? null : MapToDomain(entity);
    }

    public async Task Add(Meal meal)
    {
        MealEntity entity = MapToEntity(meal);
        await _context.AddAsync(entity);
        await _context.SaveChangesAsync();
    }

    public async Task Remove(int mealId)
    {
        await _context.Meals.Where(m => m.Id == mealId).ExecuteDeleteAsync();
        await _context.SaveChangesAsync();
    }

    private MealEntity MapToEntity(Meal meal)
    {
        return new MealEntity
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

    private Meal? MapToDomain(MealEntity? meal)
    {
        if (meal == null)
        {
            return null;
        }

        return new Meal
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
