namespace AIS.Domain.Models;

public class WeekStepsInfo
{
    public int UserID;

    public DayStepsInfo? BestDay { get; set; }

    public List<DayStepsInfo> DayStepsInfo { set; get; }

    public int TotalSteps { get; set; }
}
