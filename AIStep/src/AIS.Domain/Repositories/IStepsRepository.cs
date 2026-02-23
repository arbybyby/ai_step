using AIS.Domain.Models;

namespace AIS.Domain.Repositories;

public interface IStepsRepository
{
    public Task<DayStepsInfo> GetDayInfoAsync(int userID, DateOnly date);

    public Task<WeekStepsInfo> GetWeekInfoAsync(int userID);

    public Task SaveAsync(DayStepsInfo dayStepsInfo);
}
