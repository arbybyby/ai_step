using AIS.Infrastructure.RabbitMQ;

namespace AIS.AppAPI.HostedServices;

public class RabbitMqConsumerHostedService : BackgroundService
{
    private readonly RabbitConsumer _consumer;

    public RabbitMqConsumerHostedService(RabbitConsumer consumer)
    {
        _consumer = consumer;
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _consumer.Start();
        return Task.CompletedTask;
    }
}
