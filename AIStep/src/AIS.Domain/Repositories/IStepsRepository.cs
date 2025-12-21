using AIS.Domain.Models;

namespace AIS.Domain.Repositories;

public interface IStepsRepository
{
    public Task<DayStepsInfo> GetDayInfo(int userID, DateOnly date);

    public Task<WeekStepsInfo> GetWeekInfo(int userID);

    public Task Save(DayStepsInfo dayStepsInfo);
}
