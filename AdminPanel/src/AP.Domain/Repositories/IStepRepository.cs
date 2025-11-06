namespace AP.Domain.Repositories;

public interface IStepRepository
{
    Task<DailyStepsResult> GetDailyStepsAsync(long userId, DateOnly date);
}