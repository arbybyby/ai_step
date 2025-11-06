using AP.Domain;
using AP.Domain.Repositories;
using Microsoft.EntityFrameworkCore;

namespace AP.Database.Repositories;

public class StepsRepository : IStepRepository
{
    private readonly IDbContextFactory<AppDbContext> _contextFactory;

    public StepsRepository(IDbContextFactory<AppDbContext> context)
    {
        _contextFactory = context;
    }

    public async Task<DailyStepsResult> GetDailyStepsAsync(long userId, DateOnly date)
    {
        using var context = _contextFactory.CreateDbContext();
        var dayStart = date.ToDateTime(new TimeOnly(0, 0), DateTimeKind.Utc);
        var dayEnd = date.ToDateTime(new TimeOnly(0, 0), DateTimeKind.Utc).AddDays(1);

        var steps = await context.Steps
            .Where(s => s.UserId == userId && s.RecordedAt >= dayStart && s.RecordedAt < dayEnd)
            .ToListAsync();

        return new DailyStepsResult
        {
            UserId = userId,
            TotalSteps = steps.Sum(s => s.StepCount),
            TotalDistance = steps.Sum(s => s.DistanceM ?? 0),
            TotalCalories = steps.Sum(s => s.CaloriesBurned ?? 0)
        };
    }
}
