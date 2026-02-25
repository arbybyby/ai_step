using AIS.AdminPanel.Models;
using AIS.AdminPanel.Services;
using AIS.Domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AIS.AdminPanel.Pages;

[Authorize]
public class UserEditModel : PageModel
{
    private readonly IUserAdminService _userService;
    private readonly ILogger<UserEditModel> _logger;

    [BindProperty]
    public UserEditRequest UserRequest { get; set; } = new();

    public int UserId { get; set; }
    public string? ErrorMessage { get; set; }

    public UserEditModel(IUserAdminService userService, ILogger<UserEditModel> logger)
    {
        _userService = userService;
        _logger = logger;
    }

    public async Task<IActionResult> OnGetAsync(int id)
    {
        UserId = id;
        try
        {
            var user = await _userService.GetUserAsync(id);
            UserRequest = new UserEditRequest
            {
                Email = user.Email,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Age = user.Age,
                Gender = user.Gender,
                ActivityLevel = user.ActivityLevel,
                FitnessGoal = user.FitnessGoal,
                HeightCm = user.HeightCm,
                WeightKg = user.WeightKg,
                IsVerified = user.IsVerified
            };
        }
        catch (KeyNotFoundException)
        {
            return RedirectToPage("/Users");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading user {UserId}", id);
            return RedirectToPage("/Users");
        }
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id)
    {
        UserId = id;
        if (!ModelState.IsValid)
            return Page();

        try
        {
            var user = new User
            {
                ID = id,
                Email = UserRequest.Email,
                FirstName = UserRequest.FirstName,
                LastName = UserRequest.LastName,
                Age = UserRequest.Age,
                Gender = UserRequest.Gender,
                ActivityLevel = UserRequest.ActivityLevel,
                FitnessGoal = UserRequest.FitnessGoal,
                HeightCm = UserRequest.HeightCm,
                WeightKg = UserRequest.WeightKg,
                IsVerified = UserRequest.IsVerified
            };
            await _userService.UpdateUserAsync(user);
            TempData["SuccessMessage"] = $"Пользователь {user.FirstName} {user.LastName} успешно обновлён";
            return RedirectToPage("/Users");
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Ошибка при сохранении: {ex.Message}";
            _logger.LogError(ex, "Error updating user {UserId}", id);
            return Page();
        }
    }
}

