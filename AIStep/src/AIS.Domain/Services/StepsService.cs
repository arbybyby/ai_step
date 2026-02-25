using AIS.Domain.Exceptions;
using AIS.Domain.Models;
using AIS.Domain.Repositories;

using Microsoft.Extensions.Logging;

namespace AIS.Domain.Services;

public class StepsService
{
    private readonly IStepsRepository _stepsRepository;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<StepsService> _logger;

    public StepsService(IStepsRepository stepsRepository, IUserRepository userRepository, ILogger<StepsService> logger)
    {
        _stepsRepository = stepsRepository;
        _userRepository = userRepository;
        _logger = logger;
    }

    public async Task SaveAsync(int userID, int stepsCount)
    {
        User? user = await _userRepository.GetByIdAsync(userID);
        if (user == null)
        {
            _logger.LogError("User with ID {UserID} not found. Cannot save steps.", userID);
            throw new UserNotFoundException($"User with ID {userID} not found.");
        }

        DayStepsInfo dayStepsInfo = new()
        {
            UserID = userID,
            Date = DateOnly.FromDateTime(DateTime.Now),
            StepsCount = stepsCount,
            DistanceKM = CalculateDistance(stepsCount, height: user.HeightCm, heightIsCm: true, strideFactor: 0.415, inKilometers: true)
        };

        await _stepsRepository.SaveAsync(dayStepsInfo);
    }

    public async Task<WeekStepsInfo> GetWeekStepsInfo(int userID)
    {
        try
        {
            WeekStepsInfo weekStepsInfo = await _stepsRepository.GetWeekInfoAsync(userID);
            return weekStepsInfo;
        }
        catch (Exception ex)
        {
            return new WeekStepsInfo();
        }
    }

    public async Task<DayStepsInfo> GetDayStepsInfoAsync(int userID)
    {
        try
        {
            DayStepsInfo result = await _stepsRepository.GetDayInfoAsync(userID, DateOnly.FromDateTime(DateTime.Now));
            return result;
        }
        catch (DayStepsNotFoundException)
        {
            return new DayStepsInfo
            {
                UserID = userID,
                Date = DateOnly.FromDateTime(DateTime.Now),
                StepsCount = 0,
                DistanceKM = 0.0
            };
        }
    }

    private double EstimateStrideMeters(double height, bool heightIsCm = true, double strideFactor = 0.415)
    {
        if (height < 0.0)
        {
            _logger.LogError("Invalid height value: {Height}. Height must be greater than 0.", height);
            throw new ArgumentOutOfRangeException(nameof(height), "Height must be > 0.");
        }

        height = height == 0 ? 170.0 : height;

        double heightCm = heightIsCm ? height : height * 2.54;
        double heightMeters = heightCm / 100.0;
        return heightMeters * strideFactor;
    }

    private double EstimateDistanceMetersFromSteps(long steps, double height, bool heightIsCm = true, double strideFactor = 0.415)
    {
        if (steps < 0L)
        {
            _logger.LogError("Invalid steps value: {Steps}. Steps must be >= 0.", steps);
            throw new ArgumentOutOfRangeException(nameof(steps), "Steps must be >= 0.");
        }

        double stride = EstimateStrideMeters(height, heightIsCm, strideFactor);
        return steps * stride;
    }

    private double CalculateDistance(long steps, double height, bool heightIsCm = true, double strideFactor = 0.415, bool inKilometers = false)
    {
        if (steps < 0L)
        {
            _logger.LogError("Invalid steps value: {Steps}. Steps must be >= 0.", steps);
            throw new ArgumentOutOfRangeException(nameof(steps), "Steps must be >= 0.");
        }

        double meters = EstimateDistanceMetersFromSteps(steps, height, heightIsCm, strideFactor);
        return inKilometers ? meters / 1000.0 : meters;
    }
}
