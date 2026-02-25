using AIS.AdminPanel.Models;
using AIS.AdminPanel.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AIS.AdminPanel.Pages;

[Authorize]
public class AdminCreateModel : PageModel
{
    private readonly IAdminManageService _adminManageService;
    private readonly ILogger<AdminCreateModel> _logger;

    [BindProperty]
    public AdminCreateRequest AdminRequest { get; set; } = new();

    public string? ErrorMessage { get; set; }

    public AdminCreateModel(IAdminManageService adminManageService, ILogger<AdminCreateModel> logger)
    {
        _adminManageService = adminManageService;
        _logger = logger;
    }

    public void OnGet() { }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
            return Page();

        try
        {
            await _adminManageService.CreateAdminAsync(
                AdminRequest.Email,
                AdminRequest.Password,
                AdminRequest.FirstName,
                AdminRequest.LastName);

            TempData["SuccessMessage"] = $"Администратор {AdminRequest.FirstName} {AdminRequest.LastName} успешно создан";
            return RedirectToPage("/Admins");
        }
        catch (InvalidOperationException ex)
        {
            ErrorMessage = ex.Message;
            return Page();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating admin");
            ErrorMessage = $"Ошибка при создании администратора: {ex.Message}";
            return Page();
        }
    }
}

