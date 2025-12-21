using AIS.Domain.Models;

namespace AIS.Domain.Repositories;

public interface IWaterTrackerRepository
{
    public Task Save(WaterInfo waterInfo);

    public Task<WaterInfo> Get(int userId);

    public Task Update(WaterInfo waterInfo);
}
