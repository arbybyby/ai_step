using System.Security.Claims;

using AIS.Domain.Models;
using AIS.Domain.Repositories;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AIS.AppAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class MealsController : ControllerBase
{
    private readonly ILogger<MealsController> _logger;
    private readonly IMealRepository _mealRepository;

    public MealsController(ILogger<MealsController> logger, IMealRepository mealRepository)
    {
        _logger = logger;
        _mealRepository = mealRepository;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        string? idValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(idValue) || !int.TryParse(idValue, out int userID))
        {
            _logger.LogWarning("User id claim missing or invalid. Claim value: {ClaimValue}", idValue);
            return Unauthorized();
        }

        List<Meal?> meals = await _mealRepository.GetAll(userID);

        return Ok(meals);
    }

    [HttpGet]
    public async Task<IActionResult> GetById(int id)
    {
        Meal? meal = await _mealRepository.Get(id);
        return Ok(meal);
    }
}
