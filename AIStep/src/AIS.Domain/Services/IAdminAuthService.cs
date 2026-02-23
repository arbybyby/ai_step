using AIS.Domain.Models;

namespace AIS.Domain.Services;

public interface IAdminAuthService
{
    Task<(Admin? admin, JwtTokens? tokens)> AuthenticateAsync(string email, string password);
    Task<Admin> CreateAdminAsync(string email, string password, string firstName, string lastName);
}

