using AIS.AdminPanel.Services;
using AIS.Domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AIS.AdminPanel.Pages;

[Authorize]
public class UsersModel : PageModel
{
    private readonly IUserAdminService _userService;
    private readonly ILogger<UsersModel> _logger;

    public List<User> Users { get; set; } = [];
    public string? ErrorMessage { get; set; }
    public string? SuccessMessage { get; set; }

    public UsersModel(IUserAdminService userService, ILogger<UsersModel> logger)
    {
        _userService = userService;
        _logger = logger;
    }

    public async Task OnGetAsync()
    {
        try
        {
            Users = await _userService.GetAllUsersAsync();
            SuccessMessage = TempData["SuccessMessage"] as string;
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Ошибка при загрузке пользователей: {ex.Message}";
            _logger.LogError(ex, "Error loading users");
        }
    }

    public async Task<IActionResult> OnPostDeleteAsync(int id)
    {
        try
        {
            await _userService.DeleteUserAsync(id);
            TempData["SuccessMessage"] = "Пользователь успешно удалён";
            return RedirectToPage();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting user with id {UserId}", id);
            ErrorMessage = $"Ошибка при удалении пользователя: {ex.Message}";
            Users = await _userService.GetAllUsersAsync();
            return Page();
        }
    }
}

