namespace AIS.Domain;

public interface IEventBus
{
    Task PublishAsync(object message);
}
