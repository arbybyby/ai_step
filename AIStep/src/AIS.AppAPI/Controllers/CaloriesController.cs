using System.Security.Claims;

using AIS.Domain.Exceptions;
using AIS.Domain.Services;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AIS.AppAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CaloriesController : ControllerBase
{
    private readonly CaloriesService _caloriesService;
    private readonly ILogger<CaloriesController> _logger;

    public CaloriesController(CaloriesService caloriesService, ILogger<CaloriesController> logger)
    {
        _caloriesService = caloriesService;
        _logger = logger;
    }

    /// <summary>
    /// Returns the kilocalories burned today based on the user's steps.
    /// </summary>
    [HttpGet("burned/today")]
    public async Task<IActionResult> GetBurnedCaloriesToday()
    {
        var idValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(idValue) || !int.TryParse(idValue, out int userID))
        {
            _logger.LogWarning("User id claim missing or invalid. Claim value: {ClaimValue}", idValue);
            return Unauthorized();
        }

        try
        {
            double calories = await _caloriesService.GetCalories(userID);
            return Ok(new { caloriesBurned = calories });
        }
        catch (UserNotFoundException ex)
        {
            return NotFound(ex.Message);
        }
        catch (Exception)
        {
            return Problem(
                detail: "An unexpected error occurred while calculating burned calories.",
                statusCode: StatusCodes.Status500InternalServerError);
        }
    }

    /// <summary>
    /// Returns the kilocalories burned on a specific date based on the user's steps.
    /// Date format: yyyy-MM-dd
    /// </summary>
    [HttpGet("burned/{date}")]
    public async Task<IActionResult> GetBurnedCaloriesForDate(string date)
    {
        var idValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(idValue) || !int.TryParse(idValue, out int userID))
        {
            _logger.LogWarning("User id claim missing or invalid. Claim value: {ClaimValue}", idValue);
            return Unauthorized();
        }

        if (!DateOnly.TryParseExact(date, "yyyy-MM-dd", out DateOnly parsedDate))
        {
            return BadRequest("Invalid date format. Use yyyy-MM-dd.");
        }

        try
        {
            double calories = await _caloriesService.GetCaloriesForDate(userID, parsedDate);
            return Ok(new { date = parsedDate.ToString("yyyy-MM-dd"), caloriesBurned = calories });
        }
        catch (UserNotFoundException ex)
        {
            return NotFound(ex.Message);
        }
        catch (Exception)
        {
            return Problem(
                detail: "An unexpected error occurred while calculating burned calories.",
                statusCode: StatusCodes.Status500InternalServerError);
        }
    }
}

