using System.Text;
using System.Text.Json;

using AIS.AppAPI.Handlers;

using MediatR;

using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace AIS.Infrastructure.RabbitMQ;

public class RabbitConsumer
{
    private readonly IConfiguration _configuration;
    private readonly IConnection _connection;
    private readonly IChannel _channel;
    private readonly IMediator _mediator;
    private readonly ILogger<RabbitConsumer> _logger;

    public RabbitConsumer(IConfiguration configuration, IMediator mediator, ILogger<RabbitConsumer> logger)
    {
        _configuration = configuration;
        _mediator = mediator;
        _logger = logger;

        ConnectionFactory connectionFactory = new()
        {
            HostName = _configuration["Broker:Host"],
            UserName = _configuration["Broker:User"],
            Password = _configuration["Broker:Password"],
            VirtualHost = _configuration["Broker:VirtualHost"],
        };

        _connection = connectionFactory.CreateConnectionAsync().Result;
        _channel = _connection.CreateChannelAsync().Result;

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
                MealMessage meal = JsonSerializer.Deserialize<MealMessage>(ea.Body.ToArray());

                _mediator.Send(new MealRequest()
                {
                    Message = meal.Message
                });

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
    public string Message { get; init; }
}
