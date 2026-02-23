using AIS.Domain.Exceptions;
using AIS.Domain.Models;
using AIS.Domain.Repositories;

using Microsoft.Extensions.Logging;

namespace AIS.Domain.Services;

public class WaterTrackerService
{
    private readonly IWaterTrackerRepository _waterTrackerRepository;
    private readonly ILogger<WaterTrackerService> _logger;

    public WaterTrackerService(IWaterTrackerRepository waterTrackerRepository, ILogger<WaterTrackerService> logger)
    {
        _waterTrackerRepository = waterTrackerRepository;
        _logger = logger;
    }

    public async Task AddAsync(int userID, int waterAmount)
    {
        WaterInfo? waterInfo = await _waterTrackerRepository.Get(userID);

        if (waterInfo is null)
        {
            waterInfo = new WaterInfo
            {
                UserID = userID,
                WaterDrank = waterAmount
            };
            await _waterTrackerRepository.Save(waterInfo);
            _logger.LogInformation("Added new water info for user {UserID} with amount {WaterAmount}", userID, waterAmount);
        }
        else
        {
            waterInfo.WaterDrank += waterAmount;
            await _waterTrackerRepository.Update(waterInfo);
            _logger.LogInformation("Updated water info for user {UserID} with additional amount {WaterAmount}", userID, waterAmount);
        }
    }

    public async Task RemoveAsync(int userID, int waterAmount)
    {
        WaterInfo? waterInfo = await _waterTrackerRepository.Get(userID);
        if (waterInfo is null)
        {
            throw new WaterInfoNotFoundException($"No water info found for user with ID {userID}");
        }

        waterInfo.WaterDrank = Math.Max(0, waterInfo.WaterDrank - waterAmount);

        await _waterTrackerRepository.Update(waterInfo);

        _logger.LogInformation("Removed amount {WaterAmount} from water info for user {UserID}", waterAmount, userID);
    }

    public async Task<WaterInfo?> GetWaterInfoAsync(int userID)
    {
        WaterInfo? waterInfo = await _waterTrackerRepository.Get(userID);
        if (waterInfo is null)
        {
            throw new WaterInfoNotFoundException($"No water info found for user with ID {userID}");
        }

        _logger.LogInformation("Retrieved water info for user {UserID}: {WaterInfo}", userID, waterInfo);

        return waterInfo;
    }
}
