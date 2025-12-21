using System.ComponentModel.DataAnnotations;

namespace AIS.Database.Entities;

public class DayStepsInfoEntity
{
    [Key]
    public int ID { get; set; }

    public int UserID { get; set; }

    public DateOnly Date { get; set; }

    public long StepsCount { get; set; }
}
