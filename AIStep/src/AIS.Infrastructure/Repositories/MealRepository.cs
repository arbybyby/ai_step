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

    public async Task<List<Meal>> GetAll()
    {
        List<MealEntity> entities = await _context.Meals.ToListAsync();
        List<Meal> result = entities.Select(MapToDomain).ToList();

        return result;
    }

    public async Task<Meal> Get(int mealID)
    {
        MealEntity? entity = await _context.Meals.FindAsync(mealID);
        if (entity == null)
        {
            throw new KeyNotFoundException($"Meal with ID {mealID} not found.");
        }

        return MapToDomain(entity);
    }

    public async Task Add(Meal meal)
    {
        MealEntity entity = MapToEntity(meal);

        await _context.AddAsync(entity);
        await _context.SaveChangesAsync();
    }

    public async Task Remove(int mealID)
    {
        await _context.Meals.Where(m => m.Id == mealID).ExecuteDeleteAsync();
        await _context.SaveChangesAsync();
    }

    public async Task Update(int mealID, Meal meal)
    {
        MealEntity entity = MapToEntity(meal);
        entity.Id = mealID;

         _context.Meals.Update(entity);
        await _context.SaveChangesAsync();
    }

    private Meal MapToDomain(MealEntity entity)
    {
        return new Meal
        {
            Id = entity.Id,
            MealName = entity.MealName,
            MealType = entity.MealType,
            Calories = entity.Calories,
            Protein = entity.Protein,
            Carbs = entity.Carbs,
            Fat = entity.Fat
        };
    }

    private MealEntity MapToEntity(Meal meal)
    {
        return new MealEntity
        {
            Id = meal.Id,
            MealName = meal.MealName,
            MealType = meal.MealType,
            Calories = meal.Calories,
            Protein = meal.Protein,
            Carbs = meal.Carbs,
            Fat = meal.Fat
        };
    }
}
