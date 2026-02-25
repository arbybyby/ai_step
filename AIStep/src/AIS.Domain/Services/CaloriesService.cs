using AIS.Domain.Exceptions;
using AIS.Domain.Models;
using AIS.Domain.Repositories;

using Microsoft.Extensions.Logging;

namespace AIS.Domain.Services;

public class CaloriesService
{
    private readonly StepsService _stepsService;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<CaloriesService> _logger;

    public CaloriesService(StepsService stepsService, IUserRepository userRepository, ILogger<CaloriesService> logger)
    {
        _stepsService = stepsService;
        _userRepository = userRepository;
        _logger = logger;
    }

    public async Task<double> GetCalories(int userId)
    {
        User? user = await _userRepository.GetByIdAsync(userId);
        if (user == null)
        {
            _logger.LogError("User with ID {UserID} not found. Cannot calculate calories.", userId);
            throw new UserNotFoundException($"User with ID {userId} not found.");
        }

        DayStepsInfo dayStepsInfo = await _stepsService.GetDayStepsInfoAsync(userId);

        double caloriesBurned = CalculateCaloriesFromDistance(dayStepsInfo.DistanceKM, user.WeightKg);

        _logger.LogInformation(
            "Calculated {Calories} kcal burned for user {UserID} ({Steps} steps, {Distance} km, {Weight} kg).",
            caloriesBurned, userId, dayStepsInfo.StepsCount, dayStepsInfo.DistanceKM, user.WeightKg);

        return caloriesBurned;
    }

    public async Task<double> GetCaloriesForDate(int userId, DateOnly date)
    {
        User? user = await _userRepository.GetByIdAsync(userId);
        if (user == null)
        {
            _logger.LogError("User with ID {UserID} not found. Cannot calculate calories.", userId);
            throw new UserNotFoundException($"User with ID {userId} not found.");
        }

        WeekStepsInfo weekInfo = await _stepsService.GetWeekStepsInfo(userId);
        DayStepsInfo? dayInfo = weekInfo.DayStepsInfo?.FirstOrDefault(d => d.Date == date);

        if (dayInfo == null)
        {
            return 0.0;
        }

        return CalculateCaloriesFromDistance(dayInfo.DistanceKM, user.WeightKg);
    }

    private static double CalculateCaloriesFromDistance(double distanceKm, double weightKg)
    {
        const double caloriesPerKmPerKg = 0.9;
        return Math.Round(distanceKm * weightKg * caloriesPerKmPerKg, 2);
    }
}
