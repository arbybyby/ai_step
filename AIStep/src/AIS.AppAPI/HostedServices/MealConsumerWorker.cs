using System.Threading.Channels;

using AIS.Infrastructure.RabbitMQ;

namespace AIS.AppAPI.HostedServices;

public class MealConsumerWorker : BackgroundService
{
    private readonly ChannelReader<MealMessage?> _mealReader;
    private readonly RabbitConsumer _consumer;

    public MealConsumerWorker(RabbitConsumer consumer, ChannelReader<MealMessage?> mealReader)
    {
        _consumer = consumer;
        _mealReader = mealReader;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await _consumer.Start();
        await foreach (MealMessage? meal in _mealReader.ReadAllAsync(stoppingToken))
        {
            if (meal is not null)
            {
                Console.WriteLine(meal.Message);
            }
        }
    }
}
