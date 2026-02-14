using AIS.AdminPanel.Services;
using AIS.Domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AIS.AdminPanel.Pages;

[Authorize]
public class MealsModel : PageModel
{
    private readonly IMealService _mealService;
    private readonly ILogger<MealsModel> _logger;

    public List<Meal> Meals { get; set; } = [];
    public string? ErrorMessage { get; set; }
    public string? SuccessMessage { get; set; }

    public MealsModel(IMealService mealService, ILogger<MealsModel> logger)
    {
        _mealService = mealService;
        _logger = logger;
    }

    public async Task OnGetAsync()
    {
        try
        {
            Meals = await _mealService.GetAllMealsAsync();
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Ошибка при загрузке блюд: {ex.Message}";
            _logger.LogError(ex, "Error loading meals");
        }
    }

    public async Task<IActionResult> OnPostDeleteAsync(int id)
    {
        try
        {
            await _mealService.DeleteMealAsync(id);
            return RedirectToPage();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting meal with id {MealId}", id);
            ErrorMessage = $"Ошибка при удалении блюда: {ex.Message}";
            return Page();
        }
    }
}

