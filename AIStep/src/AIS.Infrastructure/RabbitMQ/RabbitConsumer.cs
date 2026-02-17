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
    private readonly ChannelWriter<MealMessage?> _channelAddWriter;
    private readonly ChannelWriter<DeleteMessage?> _channelDeleteWriter;

    public RabbitConsumer(ChannelWriter<MealMessage?> channelAddWriter,
        ILogger<RabbitConsumer> logger,
        IConfiguration configuration, ChannelWriter<DeleteMessage?> channelDeleteWriter)
    {
        _logger = logger;
        _channelDeleteWriter = channelDeleteWriter;
        _channelAddWriter = channelAddWriter;

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
            queue: "meals.add.queue",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null);

        _channel.QueueDeclareAsync(
            queue: "meals.delete.queue",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null);

        _channel.QueueBindAsync("meals.add.queue", "meals-exchange", "meals.add");
        _channel.QueueBindAsync("meals.delete.queue", "meals-exchange", "meals.delete");
    }

    public async Task Start()
    {
        AsyncEventingBasicConsumer addConsumer = new(_channel);
        addConsumer.ReceivedAsync += async (sender, ea) =>
        {
            try
            {
                MealMessage? meal = JsonSerializer.Deserialize<MealMessage>(ea.Body.ToArray());
                _logger.LogInformation("Received add message for MealID: {MealID}, UserID: {UserID}",
                    meal?.MealID, meal?.UserID);

                await _channelAddWriter.WriteAsync(meal);
                await _channel.BasicAckAsync(ea.DeliveryTag, false);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing add message");
                await _channel.BasicNackAsync(ea.DeliveryTag, false, true);
            }
        };

        AsyncEventingBasicConsumer deleteConsumer = new(_channel);
        deleteConsumer.ReceivedAsync += async (sender, ea) =>
        {
            try
            {
                DeleteMessage? message = JsonSerializer.Deserialize<DeleteMessage>(ea.Body.ToArray());
                _logger.LogInformation("Received delete message for MealID: {MealID}, UserID: {UserID}",
                    message?.Id, message?.UserID);

                await _channelDeleteWriter.WriteAsync(message);
                await _channel.BasicAckAsync(ea.DeliveryTag, false);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing delete message");
                await _channel.BasicNackAsync(ea.DeliveryTag, false, true);
            }
        };

        await _channel.BasicConsumeAsync(queue: "meals.add.queue", autoAck: false, consumer: addConsumer);
        await _channel.BasicConsumeAsync(queue: "meals.delete.queue", autoAck: false, consumer: deleteConsumer);

        await Task.CompletedTask;
    }

}

public class MealMessage
{
    public int UserID { get; init; }

    public int MealID { get; init; }

    public string MealType { get; init; }

    public float Grammes { get; init; }

    public DateTime Date { get; init; }
}

public class DeleteMessage
{
    public int Id { get; init; }

    public int UserID { get; init; }
}
