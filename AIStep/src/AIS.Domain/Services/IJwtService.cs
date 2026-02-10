﻿using AIS.Domain.Models;
using System.Security.Claims;

namespace AIS.Domain.Services;

public interface IJwtService
{
    string GenerateAccessToken(int userId, string email);

    string GenerateRefreshToken();

    ClaimsPrincipal? ValidateAccessToken(string token);

    Task<JwtTokens> GenerateTokensAsync(int userId, string email);

    Task<JwtTokens> GenerateTokensForAdminAsync(int adminId, string email);

    Task<JwtTokens?> RefreshTokensAsync(string refreshToken);

    Task RevokeRefreshTokenAsync(string refreshToken);
}
