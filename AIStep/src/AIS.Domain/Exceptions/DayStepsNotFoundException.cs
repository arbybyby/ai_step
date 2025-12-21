namespace AIS.Domain.Exceptions;

public class DayStepsNotFoundException : Exception
{
    public DayStepsNotFoundException()
    {
        
    }

    public DayStepsNotFoundException(string? message) : base(message)
    {
    }
}
