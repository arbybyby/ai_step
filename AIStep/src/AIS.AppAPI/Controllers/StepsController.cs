using System.Security.Claims;

using AIS.Domain.Exceptions;
using AIS.Domain.Models;
using AIS.Domain.Repositories;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AIS.AppAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class StepsController : ControllerBase
{
    private readonly IStepsRepository _stepsRepository;
    private readonly ILogger<StepsController> _logger;

    public StepsController(IStepsRepository stepsRepository, ILogger<StepsController> logger)
    {
        _stepsRepository = stepsRepository;
        _logger = logger;
    }

    [HttpGet("current-day")]
    public async Task<IActionResult> GetDayStepsInfoAsync()
    {
        var idValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(idValue) || !int.TryParse(idValue, out int userId))
        {
            _logger.LogWarning("User id claim missing or invalid. Claim value: {ClaimValue}", idValue);
            return Unauthorized();
        }

        try
        {
            DayStepsInfo result = await _stepsRepository.GetDayInfo(userId, DateOnly.FromDateTime(DateTime.Now));
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
        if (string.IsNullOrWhiteSpace(idValue) || !int.TryParse(idValue, out int userId))
        {
            _logger.LogWarning("User id claim missing or invalid. Claim value: {ClaimValue}", idValue);
            return Unauthorized();
        }

        try
        {
            var dayStepsInfo = new DayStepsInfo()
            {
                UserID = userId,
                StepsCount = steps,
                Date = DateOnly.FromDateTime(DateTime.Now)
            };

            await _stepsRepository.Save(dayStepsInfo);

            return Ok();
        }
        catch (Exception ex)
        {
            return Problem();
        }
    }
}
