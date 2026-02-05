using AIS.AppAPI.Models;
using AIS.Domain.Services;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

using System.Security.Claims;

using AIS.Domain.Repositories;

namespace AIS.AppAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly IJwtService _jwtService;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAuthService authService, IJwtService jwtService, ILogger<AuthController> logger, IUserRepository userRepository)
    {
        _authService = authService;
        _jwtService = jwtService;
        _logger = logger;
        _userRepository = userRepository;
    }

    [HttpPost("register")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        try
        {
            Console.WriteLine($"Email: {request.Email}");
            await _authService.RegisterUserAsync(request.Email, request.Password, request.FirstName, request.LastName);
            return Created("", new { message = "Registration successful. Check your email to verify." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("login")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        try
        {
            var tokens = await _authService.AuthenticateUserAsync(request.Email, request.Password);

            if (tokens == null)
            {
                return Unauthorized(new { message = "Invalid email or password" });
            }

            return Ok(new
            {
                message = "Authentication successful",
                email = request.Email,
                accessToken = tokens.AccessToken,
                refreshToken = tokens.RefreshToken,
                accessTokenExpiration = tokens.AccessTokenExpiration,
                refreshTokenExpiration = tokens.RefreshTokenExpiration
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("verify")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> VerifyEmail([FromBody] VerifyEmailRequest request)
    {
        try
        {
            var isVerified = await _authService.VerifyCodeAsync(request.Email, request.Code);

            if (!isVerified)
            {
                return BadRequest(new { message = "Invalid or expired verification code" });
            }

            return Ok(new { message = "Email verified successfully" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("resend-code")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ResendVerificationCode([FromBody] ResendCodeRequest request)
    {
        try
        {
            await _authService.SendVerificationCodeAsync(request.Email);
            return Ok(new { message = "Verification code sent to email" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("refresh")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        try
        {
            var tokens = await _jwtService.RefreshTokensAsync(request.RefreshToken);

            if (tokens == null)
            {
                return Unauthorized(new { message = "Invalid refresh token" });
            }

            return Ok(new
            {
                message = "Tokens refreshed",
                accessToken = tokens.AccessToken,
                refreshToken = tokens.RefreshToken,
                accessTokenExpiration = tokens.AccessTokenExpiration,
                refreshTokenExpiration = tokens.RefreshTokenExpiration
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("logout")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Logout([FromBody] LogoutRequest request)
    {
        try
        {
            await _jwtService.RevokeRefreshTokenAsync(request.RefreshToken);
            return NoContent();
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("me")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetCurrentUser()
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userIdString) || !int.TryParse(userIdString, out int userId))
        {
            return Unauthorized(new { message = "User not found" });
        }

        var user = await _userRepository.GetByIdAsync(userId);
        _logger.LogInformation("Current user ID: {UserId}, Email: {Email}", userId, user.Email);

        return Ok(user);
    }
}
