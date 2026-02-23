using System.Security.Claims;

using AIS.Domain.Exceptions;
using AIS.Domain.Models;
using AIS.Domain.Services;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AIS.AppAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class StepsController : ControllerBase
{
    private readonly StepsService _stepsService;
    private readonly ILogger<StepsController> _logger;

    public StepsController(StepsService stepsService, ILogger<StepsController> logger)
    {
        _logger = logger;
        _stepsService = stepsService;
    }

    [HttpGet("current-day")]
    public async Task<IActionResult> GetDayStepsInfoAsync()
    {
        var idValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(idValue) || !int.TryParse(idValue, out int userID))
        {
            _logger.LogWarning("User id claim missing or invalid. Claim value: {ClaimValue}", idValue);
            return Unauthorized();
        }

        try
        {
            DayStepsInfo result = await _stepsService.GetDayStepsInfoAsync(userID);
            return Ok(result);
        }
        catch (DayStepsNotFoundException ex)
        {
            return NotFound(ex.Message);
        }
        catch (Exception)
        {
            return Problem(
                detail: "An unexpected error occurred while retrieving day steps.",
                statusCode: StatusCodes.Status500InternalServerError);
        }
    }

    [HttpPost]
    public async Task<IActionResult> SaveDayInfo(int steps)
    {
        var idValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(idValue) || !int.TryParse(idValue, out int userID))
        {
            _logger.LogWarning("User id claim missing or invalid. Claim value: {ClaimValue}", idValue);
            return Unauthorized();
        }

        try
        {
            _logger.LogInformation("Saving day steps info for user {UserId} with {Steps} steps.", userID, steps);

            await _stepsService.SaveAsync(userID, steps);

            return Ok();
        }
        catch (Exception ex)
        {
            return Problem();
        }
    }

    [HttpGet("current-week")]
    public async Task<IActionResult> GetWeekStepsInfoAsync()
    {
        var idValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(idValue) || !int.TryParse(idValue, out int id))
        {
            return Unauthorized();
        }

        try
        {
            var weeklyProggres = await _stepsService.GetWeekStepsInfo(id);
            return Ok(weeklyProggres);
        }
        catch(Exception ex)
        {
            return Problem();
        }
    }
}
