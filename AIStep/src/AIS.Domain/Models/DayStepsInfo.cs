namespace AIS.Domain.Models;

public class DayStepsInfo
{
    public int ID { get; set; }

    public int UserID { get; set; }

    public DateOnly Date { get; set; }

    public long StepsCount { get; set; }
}
