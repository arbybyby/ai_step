using AIS.AppAPI.Handlers;

using MediatR;

namespace AIS.AppAPI.MediatorHandlers;

public class MealRequestHandler : IRequestHandler<MealRequest>
{
        public Task Handle(MealRequest request, CancellationToken cancellationToken)
        {
            Console.WriteLine($"Message {request.Message}");
            return Task.CompletedTask;
        }
}
