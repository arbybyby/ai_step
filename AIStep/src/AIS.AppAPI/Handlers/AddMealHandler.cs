using MediatR;

namespace AIS.AppAPI.Handlers;

public class MealRequest : IRequest
{
    public int UserID;
}

public class AddMealHandler : IRequestHandler<MealRequest>
{
    public Task Handle(MealRequest request, CancellationToken cancellationToken)
    {
        throw new NotImplementedException();
    }
}
