using AIS.Domain.Models;
using AIS.Domain.Repositories;
using Microsoft.Extensions.Logging;

namespace AIS.AdminPanel.Services;

public class MealService : IMealService
{
    private readonly IMealRepository _mealRepository;
    private readonly ILogger<MealService> _logger;

    public MealService(IMealRepository mealRepository, ILogger<MealService> logger)
    {
        _mealRepository = mealRepository;
        _logger = logger;
    }

    public async Task<List<Meal>> GetAllMealsAsync()
    {
        try
        {
            return await _mealRepository.GetAll();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting all meals");
            throw;
        }
    }

    public async Task<Meal> GetMealAsync(int id)
    {
        try
        {
            return await _mealRepository.Get(id);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting meal with id {MealId}", id);
            throw;
        }
    }

    public async Task<Meal> CreateMealAsync(Meal meal)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(meal.MealName))
            {
                throw new ArgumentException("Meal name cannot be empty");
            }

            if (meal.Calories < 0 || meal.Protein < 0 || meal.Carbs < 0 || meal.Fat < 0)
            {
                throw new ArgumentException("Nutritional values cannot be negative");
            }

            await _mealRepository.Add(meal);
            return meal;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating meal");
            throw;
        }
    }

    public async Task UpdateMealAsync(int id, Meal meal)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(meal.MealName))
            {
                throw new ArgumentException("Meal name cannot be empty");
            }

            if (meal.Calories < 0 || meal.Protein < 0 || meal.Carbs < 0 || meal.Fat < 0)
            {
                throw new ArgumentException("Nutritional values cannot be negative");
            }

            await _mealRepository.Update(id, meal);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating meal with id {MealId}", id);
            throw;
        }
    }

    public async Task DeleteMealAsync(int id)
    {
        try
        {
            await _mealRepository.Remove(id);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting meal with id {MealId}", id);
            throw;
        }
    }
}

