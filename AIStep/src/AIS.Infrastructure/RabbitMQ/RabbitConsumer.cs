using System.Text.Json;
using System.Threading.Channels;

using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace AIS.Infrastructure.RabbitMQ;

public class RabbitConsumer
{
    private readonly IChannel _channel;
    private readonly ILogger<RabbitConsumer> _logger;
    private readonly ChannelWriter<MealMessage?> _channelWriter;

    public RabbitConsumer(ChannelWriter<MealMessage?> channelWriter,
        ILogger<RabbitConsumer> logger,
        IConfiguration configuration)
    {
        _logger = logger;
        _channelWriter = channelWriter;

        ConnectionFactory connectionFactory = new()
        {
            HostName = configuration["Broker:Host"] ?? "localhost",
            UserName = configuration["Broker:User"] ?? "guest",
            Password = configuration["Broker:Password"] ?? "guest",
            VirtualHost = configuration["Broker:VirtualHost"] ?? "/",
        };

        IConnection connection = connectionFactory.CreateConnectionAsync().Result;
        _channel = connection.CreateChannelAsync().Result;

        _channel.ExchangeDeclareAsync(
            exchange: "meals-exchange",
            type: ExchangeType.Topic,
            durable: true);

        _channel.QueueDeclareAsync(
            queue: "meals-queue",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null);

        _channel.QueueBindAsync("meals-queue", "meals-exchange", "meals");
    }

    public async Task Start()
    {
        AsyncEventingBasicConsumer consumer = new(_channel);

        consumer.ReceivedAsync += async (sender, ea) =>
        {
            try
            {
                MealMessage? meal = JsonSerializer.Deserialize<MealMessage>(ea.Body.ToArray());

                await _channelWriter.WriteAsync(meal);

                await _channel.BasicAckAsync(ea.DeliveryTag, false);
            }
            catch (Exception ex)
            {
                _logger.LogError("Error: {Error}", ex.Message);
            }
        };

        await _channel.BasicConsumeAsync(queue: "meals-queue", autoAck: false, consumer: consumer);

        await Task.CompletedTask;
    }
}

public class MealMessage
{
    public string Message { get; init; } = string.Empty;
}
