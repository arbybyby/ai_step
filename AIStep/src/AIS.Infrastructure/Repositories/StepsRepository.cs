﻿using AIS.Domain.Exceptions;
using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Infrastructure.Entities;

using Microsoft.EntityFrameworkCore;

namespace AIS.Infrastructure.Repositories;

public class StepsRepository : IStepsRepository
{
    private readonly AppDBContext _dbContext;

    public StepsRepository(AppDBContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<DayStepsInfo> GetDayInfoAsync(int userID, DateOnly date)
    {
        var entity = await _dbContext.DayStepsInfos.FirstOrDefaultAsync(d => d.UserID == userID && d.Date == date);

        if (entity is null)
        {
            throw new DayStepsNotFoundException("DaySteps not found");
        }

        return MapToDomain(entity);
    }

    public async Task<WeekStepsInfo> GetWeekInfoAsync(int userID)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var daysToSubtract = ((int)DateTime.UtcNow.DayOfWeek + 6) % 7;
        var weekStart = today.AddDays(-daysToSubtract);
        var weekEnd = weekStart.AddDays(6);

        var entities = await _dbContext.DayStepsInfos
            .Where(d => d.UserID == userID && d.Date >= weekStart && d.Date <= weekEnd)
            .ToListAsync();

        List<DayStepsInfo> dayStepsInfos = entities.Select(MapToDomain).ToList();
        int totalSteps = dayStepsInfos.Sum(d => d.StepsCount);
        DayStepsInfo bestDay = dayStepsInfos.OrderByDescending(d => d.StepsCount).First();

        return new WeekStepsInfo
        {
            UserID = userID,
            DayStepsInfo = dayStepsInfos,
            TotalSteps = totalSteps,
            BestDay = bestDay
        };
    }

    public async Task SaveAsync(DayStepsInfo dayStepsInfo)
    {
        var entity = MapToEntity(dayStepsInfo);

        var existingEntity = await _dbContext.DayStepsInfos
            .FirstOrDefaultAsync(d => d.UserID == dayStepsInfo.UserID && d.Date == dayStepsInfo.Date);

        if (existingEntity != null)
        {
            existingEntity.StepsCount = entity.StepsCount;
            existingEntity.DistanceKM = entity.DistanceKM;
            _dbContext.DayStepsInfos.Update(existingEntity);
        }
        else
        {
            await _dbContext.DayStepsInfos.AddAsync(entity);
        }

        await _dbContext.SaveChangesAsync();
    }

    private DayStepsInfo MapToDomain(DayStepsInfoEntity dayStepsInfoEntity)
    {
        return new DayStepsInfo
        {
            ID = dayStepsInfoEntity.ID,
            UserID = dayStepsInfoEntity.UserID,
            Date = dayStepsInfoEntity.Date,
            StepsCount = dayStepsInfoEntity.StepsCount,
            DistanceKM = dayStepsInfoEntity.DistanceKM
        };
    }

    private DayStepsInfoEntity MapToEntity(DayStepsInfo dayStepsInfo)
    {
        return new DayStepsInfoEntity
        {
            ID = dayStepsInfo.ID,
            UserID = dayStepsInfo.UserID,
            Date = dayStepsInfo.Date,
            StepsCount = dayStepsInfo.StepsCount,
            DistanceKM = dayStepsInfo.DistanceKM
        };
    }
}
