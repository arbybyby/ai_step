using AIS.AdminPanel.Services;
using AIS.Domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AIS.AdminPanel.Pages;

[Authorize]
public class AdminsModel : PageModel
{
    private readonly IAdminManageService _adminManageService;
    private readonly ILogger<AdminsModel> _logger;

    public List<Admin> Admins { get; set; } = [];
    public string? ErrorMessage { get; set; }
    public string? SuccessMessage { get; set; }

    public AdminsModel(IAdminManageService adminManageService, ILogger<AdminsModel> logger)
    {
        _adminManageService = adminManageService;
        _logger = logger;
    }

    public async Task OnGetAsync()
    {
        try
        {
            Admins = await _adminManageService.GetAllAdminsAsync();
            SuccessMessage = TempData["SuccessMessage"] as string;
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Ошибка при загрузке администраторов: {ex.Message}";
            _logger.LogError(ex, "Error loading admins");
        }
    }

    public async Task<IActionResult> OnPostDeleteAsync(int id)
    {
        try
        {
            await _adminManageService.DeleteAdminAsync(id);
            TempData["SuccessMessage"] = "Администратор успешно удалён";
            return RedirectToPage();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting admin with id {AdminId}", id);
            ErrorMessage = $"Ошибка при удалении администратора: {ex.Message}";
            Admins = await _adminManageService.GetAllAdminsAsync();
            return Page();
        }
    }
}

