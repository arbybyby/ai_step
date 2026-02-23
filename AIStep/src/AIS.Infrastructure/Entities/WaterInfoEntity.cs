using System.ComponentModel.DataAnnotations;

namespace AIS.Infrastructure.Entities;

public class WaterInfoEntity
{
    [Key]
    public int Id { get; set; }

    public int UserID { get; set; }

    public int WaterDrank { get; set; }
}
