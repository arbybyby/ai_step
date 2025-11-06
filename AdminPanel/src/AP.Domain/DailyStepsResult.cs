namespace AP.Domain;

public class DailyStepsResult
{
    public long UserId { get; set; }

    public long TotalSteps { get; set; }

    public double TotalDistance { get; set; }

    public double TotalCalories { get; set; }
}
