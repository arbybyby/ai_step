﻿using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Domain.Services;

namespace AIS.Infrastructure.Services;

public class AdminAuthService : IAdminAuthService
{
    private readonly IAdminRepository _adminRepository;
    private readonly IJwtService _jwtService;

    public AdminAuthService(IAdminRepository adminRepository, IJwtService jwtService)
    {
        _adminRepository = adminRepository;
        _jwtService = jwtService;
    }

    public async Task<(Admin? admin, JwtTokens? tokens)> AuthenticateAsync(string email, string password)
    {
        var admin = await _adminRepository.GetByEmailAsync(email);
        if (admin == null)
        {
            return (null, null);
        }

        var isValidPassword = await _adminRepository.ValidatePasswordAsync(email, password);
        if (!isValidPassword)
        {
            return (null, null);
        }

        var tokens = await _jwtService.GenerateTokensForAdminAsync(admin.Id, email);
        return (admin, tokens);
    }

    public async Task<Admin> CreateAdminAsync(string email, string password, string firstName, string lastName)
    {
        var existingAdmin = await _adminRepository.GetByEmailAsync(email);
        if (existingAdmin != null)
        {
            throw new InvalidOperationException("Admin with this email already exists");
        }

        var passwordHash = BCrypt.Net.BCrypt.HashPassword(password);

        var admin = new Admin
        {
            Email = email,
            FirstName = firstName,
            LastName = lastName
        };

        return await _adminRepository.CreateAsync(admin, passwordHash);
    }
}

