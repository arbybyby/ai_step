using MediatR;

namespace AIS.AppAPI.Handlers;

public class MealRequest : IRequest
{
    public int UserID;
    public string Message;
}


