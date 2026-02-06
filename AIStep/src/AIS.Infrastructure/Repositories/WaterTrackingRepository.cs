using AIS.Domain.Exceptions;
using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Infrastructure.Entities;

using Microsoft.EntityFrameworkCore;

namespace AIS.Infrastructure.Repositories;

public class WaterTrackingRepository : IWaterTrackerRepository
{
    private readonly AppDBContext _appDBContext;

    public WaterTrackingRepository(AppDBContext appDBContext)
    {
        _appDBContext = appDBContext;
    }

    public async Task<WaterInfo?> Get(int userId)
    {
        WaterInfoEntity entity = await _appDBContext.WaterInfos
            .FirstOrDefaultAsync(w => w.UserID == userId);

        if (entity is null)
        {
            return null;
        }

        return MapToDomain(entity);
    }

    public async Task Save(WaterInfo waterInfo)
    {
        WaterInfoEntity entity = MapToEntity(waterInfo);
        await _appDBContext.WaterInfos.AddAsync(entity);
        await _appDBContext.SaveChangesAsync();
    }

    public async Task Update(WaterInfo waterInfo)
    {
        WaterInfoEntity entity = await _appDBContext.WaterInfos
            .FirstOrDefaultAsync(w => w.Id == waterInfo.Id) ?? throw new WaterInfoNotFoundException("Water info not found");
        entity.WaterDrank = waterInfo.WaterDrank;
        _appDBContext.WaterInfos.Update(entity);
        await _appDBContext.SaveChangesAsync();
    }

    private WaterInfoEntity MapToEntity(WaterInfo waterInfo)
    {
        return new WaterInfoEntity
        {
            Id = waterInfo.Id,
            UserID = waterInfo.UserID,
            WaterDrank = waterInfo.WaterDrank
        };
    }

    private WaterInfo MapToDomain(WaterInfoEntity entity)
    {
        return new WaterInfo
        {
            Id = entity.Id,
            UserID = entity.UserID,
            WaterDrank = entity.WaterDrank
        };
    }
}
