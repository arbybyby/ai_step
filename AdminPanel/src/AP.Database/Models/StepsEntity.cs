using System.ComponentModel.DataAnnotations.Schema;

namespace AP.Database.Models;

[Table("steps")]
public class StepsEntity
{
    [Column("id")]
    public long Id { get; set; }

    [Column("user_id")]
    public long UserId { get; set; }

    [Column("step_count")]
    public int StepCount { get; set; }

    [Column("distance_m")]
    public double? DistanceM { get; set; }

    [Column("calories_burned")]
    public double? CaloriesBurned { get; set; }

    [Column("recorded_at")]
    public DateTime RecordedAt { get; set; }

    [Column("recorded_date")]
    public DateOnly RecordedDate { get; set; }
}
