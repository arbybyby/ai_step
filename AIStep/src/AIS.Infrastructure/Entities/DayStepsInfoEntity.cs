using System.ComponentModel.DataAnnotations;

namespace AIS.Infrastructure.Entities;

public class DayStepsInfoEntity
{
    [Key]
    public int ID { get; set; }

    public int UserID { get; set; }

    public DateOnly Date { get; set; }

    public int StepsCount { get; set; }

    public double DistanceKM { get; set; }
}
