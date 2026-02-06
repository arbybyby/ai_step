using AIS.Infrastructure.Entities;
using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Domain.Services;

using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace AIS.Infrastructure.Services;

public class JwtService : IJwtService
{
    private readonly IConfiguration _configuration;
    private readonly IRefreshTokenRepository _refreshTokenRepository;
    private readonly IUserRepository _userRepository;

    public JwtService(
        IConfiguration configuration,
        IRefreshTokenRepository refreshTokenRepository,
        IUserRepository userRepository)
    {
        _configuration = configuration;
        _refreshTokenRepository = refreshTokenRepository;
        _userRepository = userRepository;
    }

    public string GenerateAccessToken(int userId, string email)
    {
        var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
            _configuration["Jwt:Secret"] ?? throw new InvalidOperationException("Jwt:Secret is not configured")));
        
        var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, email),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(ClaimTypes.NameIdentifier, userId.ToString())
        };

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(
                double.Parse(_configuration["Jwt:AccessTokenExpirationMinutes"] ?? "15")),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string GenerateRefreshToken()
    {
        var randomNumber = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);
        return Convert.ToBase64String(randomNumber);
    }

    public ClaimsPrincipal? ValidateAccessToken(string token)
    {
        var tokenHandler = new JwtSecurityTokenHandler();
        var key = Encoding.UTF8.GetBytes(
            _configuration["Jwt:Secret"] ?? throw new InvalidOperationException("Jwt:Secret is not configured"));

        try
        {
            var principal = tokenHandler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = _configuration["Jwt:Issuer"],
                ValidateAudience = true,
                ValidAudience = _configuration["Jwt:Audience"],
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            }, out SecurityToken validatedToken);

            return principal;
        }
        catch
        {
            return null;
        }
    }

    public async Task<JwtTokens> GenerateTokensAsync(int userId, string email)
    {
        var accessToken = GenerateAccessToken(userId, email);
        var refreshToken = GenerateRefreshToken();

        var accessTokenExpiration = DateTime.UtcNow.AddMinutes(
            double.Parse(_configuration["Jwt:AccessTokenExpirationMinutes"] ?? "15"));
        
        var refreshTokenExpiration = DateTime.UtcNow.AddDays(
            double.Parse(_configuration["Jwt:RefreshTokenExpirationDays"] ?? "7"));

        var refreshTokenModel = new RefreshToken
        {
            UserId = userId,
            Token = refreshToken,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = refreshTokenExpiration,
            IsRevoked = false
        };

        await _refreshTokenRepository.AddAsync(refreshTokenModel);
        await _refreshTokenRepository.SaveChangesAsync();

        return new JwtTokens
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            AccessTokenExpiration = accessTokenExpiration,
            RefreshTokenExpiration = refreshTokenExpiration
        };
    }

    public async Task<JwtTokens?> RefreshTokensAsync(string refreshToken)
    {
        var storedToken = await _refreshTokenRepository.GetByTokenAsync(refreshToken);

        if (storedToken == null || storedToken.IsRevoked || storedToken.ExpiresAt <= DateTime.UtcNow)
        {
            return null;
        }

        storedToken.IsRevoked = true;
        await _refreshTokenRepository.UpdateAsync(storedToken);
        await _refreshTokenRepository.SaveChangesAsync();

        var user = await _userRepository.GetByIdAsync(storedToken.UserId);
        
        if (user == null)
        {
            return null;
        }

        var newTokens = await GenerateTokensAsync(user.ID, user.Email);

        storedToken.ReplacedByToken = newTokens.RefreshToken;
        await _refreshTokenRepository.UpdateAsync(storedToken);
        await _refreshTokenRepository.SaveChangesAsync();

        return newTokens;
    }

    public async Task RevokeRefreshTokenAsync(string refreshToken)
    {
        var storedToken = await _refreshTokenRepository.GetByTokenAsync(refreshToken);

        if (storedToken != null && !storedToken.IsRevoked)
        {
            storedToken.IsRevoked = true;
            await _refreshTokenRepository.UpdateAsync(storedToken);
            await _refreshTokenRepository.SaveChangesAsync();
        }
    }
}
