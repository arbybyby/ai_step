using AIS.Database.Entities;
using AIS.Domain.Exceptions;
using AIS.Domain.Models;
using AIS.Domain.Repositories;

using Microsoft.EntityFrameworkCore;

namespace AIS.Database.Repositories;

public class StepsRepository : IStepsRepository
{
    private readonly AppDBContext _dbContext;

    public StepsRepository(AppDBContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<DayStepsInfo> GetDayInfo(int userID, DateOnly date)
    {
        var entity = await _dbContext.DayStepsInfos.FirstOrDefaultAsync(d => d.UserID == userID && d.Date == date);

        if (entity is null)
        {
            throw new DayStepsNotFoundException("DaySteps not found");
        }

        return MapToDomain(entity);
    }

    public async Task Save(DayStepsInfo dayStepsInfo)
    {
        var entity = MapToEntity(dayStepsInfo);
        
        var existingEntity = await _dbContext.DayStepsInfos
            .FirstOrDefaultAsync(d => d.UserID == dayStepsInfo.UserID && d.Date == dayStepsInfo.Date);
        
        if (existingEntity != null)
        {
            existingEntity.StepsCount = entity.StepsCount;
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
        };
    }
}
