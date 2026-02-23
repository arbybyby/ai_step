using AIS.Domain.Models;

namespace AIS.Domain.Services;

public interface IAuthService
{
    Task RegisterUserAsync(string email, string password, string firstName, string lastName);

    Task<JwtTokens?> AuthenticateUserAsync(string email, string password);

    Task SendVerificationCodeAsync(string email);

    Task<bool> VerifyCodeAsync(string email, string code);

    Task SendPasswordResetCodeAsync(string email);

    Task ResetPasswordAsync(string email, string code, string newPassword);
}
