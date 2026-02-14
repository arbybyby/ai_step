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
    private readonly IUserMealRepository _userMealRepository;
    private readonly IMealRepository _mealRepository;

    public MealsController(IUserMealRepository userMealRepository, IMealRepository mealRepository,
        ILogger<MealsController> logger)
    {
        _userMealRepository = userMealRepository;
        _mealRepository = mealRepository;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> GetAllMeals()
    {
        List<Meal> meals = await _mealRepository.GetAll();
        return Ok(meals);
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

        List<UserMeal?> meals = await _userMealRepository.GetAll(userID);

        return Ok(meals);
    }

    [HttpGet]
    public async Task<IActionResult> GetById(int id)
    {
        UserMeal? meal = await _userMealRepository.Get(id);
        return Ok(meal);
    }
}
