using AIS.AdminPanel.Models;
using AIS.AdminPanel.Services;
using AIS.Domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AIS.AdminPanel.Pages;

[Authorize]
public class MealEditModel : PageModel
{
    private readonly IMealService _mealService;
    private readonly ILogger<MealEditModel> _logger;

    [BindProperty]
    public MealRequest MealRequest { get; set; } = new();

    public Meal? ExistingMeal { get; set; }
    public bool IsEdit { get; set; }
    public string? ErrorMessage { get; set; }

    public MealEditModel(IMealService mealService, ILogger<MealEditModel> logger)
    {
        _mealService = mealService;
        _logger = logger;
    }

    public async Task<IActionResult> OnGetAsync(int? id)
    {
        if (id.HasValue)
        {
            try
            {
                ExistingMeal = await _mealService.GetMealAsync(id.Value);
                IsEdit = true;

                // Populate the form with existing data
                MealRequest = new MealRequest
                {
                    MealName = ExistingMeal.MealName,
                    MealType = ExistingMeal.MealType,
                    Calories = ExistingMeal.Calories,
                    Protein = ExistingMeal.Protein,
                    Carbs = ExistingMeal.Carbs,
                    Fat = ExistingMeal.Fat
                };
            }
            catch (KeyNotFoundException)
            {
                ErrorMessage = "Блюдо не найдено";
                return RedirectToPage("/Meals");
            }
            catch (Exception ex)
            {
                ErrorMessage = $"Ошибка при загрузке блюда: {ex.Message}";
                _logger.LogError(ex, "Error loading meal with id {MealId}", id.Value);
                return RedirectToPage("/Meals");
            }
        }
        else
        {
            IsEdit = false;
        }

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int? id)
    {
        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            var meal = new Meal
            {
                MealName = MealRequest.MealName,
                MealType = MealRequest.MealType,
                Calories = MealRequest.Calories,
                Protein = MealRequest.Protein,
                Carbs = MealRequest.Carbs,
                Fat = MealRequest.Fat
            };

            if (id.HasValue)
            {
                // Update existing meal
                await _mealService.UpdateMealAsync(id.Value, meal);
                TempData["SuccessMessage"] = "Блюдо успешно обновлено";
            }
            else
            {
                // Create new meal
                await _mealService.CreateMealAsync(meal);
                TempData["SuccessMessage"] = "Блюдо успешно добавлено";
            }

            return RedirectToPage("/Meals");
        }
        catch (ArgumentException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            IsEdit = id.HasValue;
            return Page();
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Ошибка при сохранении блюда: {ex.Message}";
            _logger.LogError(ex, "Error saving meal");
            IsEdit = id.HasValue;
            return Page();
        }
    }
}

