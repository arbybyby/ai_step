﻿using AIS.AdminPanel.Models;
using AIS.Domain.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Security.Claims;

namespace AIS.AdminPanel.Pages;

[IgnoreAntiforgeryToken]
public class LoginModel : PageModel
{
    private readonly IAdminAuthService _adminAuthService;
    private readonly ILogger<LoginModel> _logger;

    [BindProperty]
    public LoginRequest LoginRequest { get; set; } = new();

    public string? ErrorMessage { get; set; }

    public LoginModel(IAdminAuthService adminAuthService, ILogger<LoginModel> logger)
    {
        _adminAuthService = adminAuthService;
        _logger = logger;
    }

    public void OnGet()
    {
        if (User.Identity?.IsAuthenticated ?? false)
        {
            RedirectToPage("/Index");
        }
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
        {
            ErrorMessage = "Пожалуйста заполните все поля";
            return Page();
        }

        try
        {
            _logger.LogInformation("Attempting login for admin: {Email}", LoginRequest.Email);

            var (admin, tokens) = await _adminAuthService.AuthenticateAsync(LoginRequest.Email, LoginRequest.Password);

            if (admin != null && tokens != null)
            {
                // Create claims for authentication
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.NameIdentifier, admin.Id.ToString()),
                    new Claim(ClaimTypes.Email, admin.Email),
                    new Claim(ClaimTypes.Name, $"{admin.FirstName} {admin.LastName}"),
                    new Claim(ClaimTypes.GivenName, admin.FirstName),
                    new Claim(ClaimTypes.Surname, admin.LastName)
                };

                var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
                var authProperties = new AuthenticationProperties
                {
                    ExpiresUtc = tokens.AccessTokenExpiration,
                    IsPersistent = true,
                    AllowRefresh = true
                };

                await HttpContext.SignInAsync(
                    CookieAuthenticationDefaults.AuthenticationScheme,
                    new ClaimsPrincipal(claimsIdentity),
                    authProperties);

                _logger.LogInformation("Admin {Email} logged in successfully", admin.Email);

                return RedirectToPage("/Index");
            }
            else
            {
                ErrorMessage = "Неверный email или пароль";
                _logger.LogWarning("Login failed for admin: {Email}", LoginRequest.Email);
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Ошибка при входе: {ex.Message}";
            _logger.LogError(ex, "Exception during login for admin: {Email}", LoginRequest.Email);
        }

        return Page();
    }
}

