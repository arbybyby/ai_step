namespace AIS.Domain.Exceptions;

public class WaterInfoNotFoundException : Exception
{
    public WaterInfoNotFoundException()
    {
    }

    public WaterInfoNotFoundException(string? message) : base(message)
    {
    }
}
