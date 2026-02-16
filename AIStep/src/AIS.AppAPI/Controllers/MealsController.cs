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

    [HttpGet("/all-meals")]
    public async Task<IActionResult> GetAllMeals()
    {
        try
        {
            List<Meal> meals = await _mealRepository.GetAll();
            _logger.LogInformation("Meals: {Meals}", meals);
            return Ok(meals);
        }
        catch (Exception ex)
        {
            _logger.LogError("Error: {Message}", ex.Message);
            return Problem(ex.Message);
        }
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

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        UserMeal? meal = await _userMealRepository.Get(id);
        return Ok(meal);
    }
}
