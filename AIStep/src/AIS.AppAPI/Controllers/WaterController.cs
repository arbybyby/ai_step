using System.Security.Claims;

using AIS.Domain.Exceptions;
using AIS.Domain.Services;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AIS.AppAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class WaterController : ControllerBase
{
    private readonly WaterTrackerService _waterTrackerService;
    private readonly ILogger<WaterController> _logger;

    public WaterController(WaterTrackerService waterTrackerService, ILogger<WaterController> logger)
    {
        _waterTrackerService = waterTrackerService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> GetWaterInfoAsync()
    {
        var idValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(idValue) || !int.TryParse(idValue, out int userID))
        {
            _logger.LogWarning("User id claim missing or invalid. Claim value: {ClaimValue}", idValue);
            return Unauthorized();
        }

        try
        {
            var result = await _waterTrackerService.GetWaterInfoAsync(userID);
            return Ok(result);
        }
        catch(WaterInfoNotFoundException ex)
        {
            return NotFound(ex.Message);
        }
        catch (Exception)
        {
            return Problem(
                detail: "An unexpected error occurred while retrieving water info.",
                statusCode: StatusCodes.Status500InternalServerError);
        }
    }

    [HttpPost("add")]
    public async Task<IActionResult> AddWaterAsync(int amount)
    {
        var idValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(idValue) || !int.TryParse(idValue, out int userID))
        {
            _logger.LogWarning("User id claim missing or invalid. Claim value: {ClaimValue}", idValue);
            return Unauthorized();
        }

        try
        {
            await _waterTrackerService.AddAsync(userID, amount);
            return Ok();
        }
        catch (Exception)
        {
            return Problem(
                detail: "An unexpected error occurred while adding water.",
                statusCode: StatusCodes.Status500InternalServerError);
        }
    }

    [HttpDelete("remove")]
    public async Task<IActionResult> RemoveWaterAsync(int amount)
    {
        var idValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(idValue) || !int.TryParse(idValue, out int userID))
        {
            _logger.LogWarning("User id claim missing or invalid. Claim value: {ClaimValue}", idValue);
            return Unauthorized();
        }

        try
        {
            await _waterTrackerService.RemoveAsync(userID, amount);
            return Ok();
        }
        catch (WaterInfoNotFoundException ex)
        {
            return NotFound(ex.Message);
        }
        catch (Exception)
        {
            return Problem(
                detail: "An unexpected error occurred while removing water.",
                statusCode: StatusCodes.Status500InternalServerError);
        }
    }
}
