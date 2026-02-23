using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Domain.Services;

using System.Security.Cryptography;
using System.Text;

using AIS.Infrastructure.Entities;
using AIS.Infrastructure.Repositories;

namespace AIS.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly IUserRepository _userRepository;
    private readonly IVerificationCodeRepository _verificationCodeRepository;
    private readonly IEmailService _emailService;
    private readonly IJwtService _jwtService;
    private readonly UserRepository _userRepositoryImpl;

    public AuthService(
        IUserRepository userRepository,
        IVerificationCodeRepository verificationCodeRepository,
        IEmailService emailService,
        IJwtService jwtService)
    {
        _userRepository = userRepository;
        _verificationCodeRepository = verificationCodeRepository;
        _emailService = emailService;
        _jwtService = jwtService;
        _userRepositoryImpl = (UserRepository)userRepository;
    }

    public async Task RegisterUserAsync(string email, string password, string firstName, string lastName)
    {
        if (string.IsNullOrWhiteSpace(email) || !email.Contains('@'))
            throw new ArgumentException("Invalid email address");

        if (string.IsNullOrWhiteSpace(password) || password.Length < 6)
            throw new ArgumentException("Password must contain at least 6 characters");

        if (string.IsNullOrWhiteSpace(firstName))
            throw new ArgumentException("First name cannot be empty");

        if (string.IsNullOrWhiteSpace(lastName))
            throw new ArgumentException("Last name cannot be empty");

        if (await _userRepository.ExistsAsync(email))
            throw new InvalidOperationException("User with this email already exists");

        var passwordHash = HashPassword(password);

        var userEntity = new UserEntity
        {
            Email = email,
            FirstName = firstName,
            LastName = lastName,
            PasswordHash = passwordHash,
            IsVerified = false,
            CreatedAt = DateTime.UtcNow
        };

        await _userRepositoryImpl.AddEntityAsync(userEntity);
        await _userRepository.SaveChangesAsync();

        await SendVerificationCodeAsync(email);
    }

    public async Task<JwtTokens?> AuthenticateUserAsync(string email, string password)
    {
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
            return null;

        var userEntity = await _userRepositoryImpl.GetEntityByEmailAsync(email);

        if (userEntity == null)
        {
            return null;
        }

        var passwordHash = HashPassword(password);

        if (userEntity.PasswordHash != passwordHash)
        {
            return null;
        }

        if (!userEntity.IsVerified)
        {
            throw new InvalidOperationException("Email not verified. Please check your email.");
        }

        var tokens = await _jwtService.GenerateTokensAsync(userEntity.ID, userEntity.Email);

        return tokens;
    }

    public async Task SendVerificationCodeAsync(string email)
    {
        var user = await _userRepository.GetByEmailAsync(email);

        if (user == null)
        {
            throw new InvalidOperationException("User not found");
        }

        var code = GenerateVerificationCode();

        var verificationCode = new VerificationCode
        {
            Email = email,
            Code = code,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddMinutes(10),
            IsUsed = false
        };

        await _verificationCodeRepository.AddAsync(verificationCode);
        await _verificationCodeRepository.SaveChangesAsync();

        await _emailService.SendVerificationCodeAsync(email, code);
    }

    public async Task<bool> VerifyCodeAsync(string email, string code)
    {
        var verificationCode = await _verificationCodeRepository.GetValidCodeAsync(email, code);

        if (verificationCode == null)
            return false;

        verificationCode.IsUsed = true;
        await _verificationCodeRepository.UpdateAsync(verificationCode);
        await _verificationCodeRepository.SaveChangesAsync();

        var user = await _userRepository.GetByEmailAsync(email);

        if (user != null)
        {
            user.IsVerified = true;
            await _userRepository.UpdateAsync(user);
            await _userRepository.SaveChangesAsync();
        }

        return true;
    }

    public async Task SendPasswordResetCodeAsync(string email)
    {
        var user = await _userRepository.GetByEmailAsync(email);
        if (user == null)
            throw new InvalidOperationException("User not found");

        var code = GenerateVerificationCode();

        var verificationCode = new VerificationCode
        {
            Email = email,
            Code = code,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddMinutes(10),
            IsUsed = false
        };

        await _verificationCodeRepository.AddAsync(verificationCode);
        await _verificationCodeRepository.SaveChangesAsync();

        await _emailService.SendVerificationCodeAsync(email, code);
    }

    public async Task ResetPasswordAsync(string email, string code, string newPassword)
    {
        var verificationCode = await _verificationCodeRepository.GetValidCodeAsync(email, code);
        if (verificationCode == null || verificationCode.IsUsed || verificationCode.ExpiresAt < DateTime.UtcNow)
            throw new InvalidOperationException("Invalid or expired code");

        var user = await _userRepositoryImpl.GetEntityByEmailAsync(email);
        if (user == null)
        {
            throw new InvalidOperationException("User not found");
        }

        user.PasswordHash = HashPassword(newPassword);
        await _userRepositoryImpl.UpdatePasswordAsync(user);
        await _userRepository.SaveChangesAsync();

        verificationCode.IsUsed = true;
        await _verificationCodeRepository.UpdateAsync(verificationCode);
        await _verificationCodeRepository.SaveChangesAsync();
    }


    private string HashPassword(string password)
    {
        using var sha256 = SHA256.Create();
        var bytes = Encoding.UTF8.GetBytes(password);
        var hash = sha256.ComputeHash(bytes);
        return Convert.ToBase64String(hash);
    }

    private string GenerateVerificationCode()
    {
        var random = new Random();
        return random.Next(100000, 999999).ToString();
    }
}
