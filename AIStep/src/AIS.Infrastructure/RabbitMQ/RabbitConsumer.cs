using System.Text;
using System.Text.Json;

using Microsoft.Extensions.Configuration;

using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace AIS.Infrastructure.RabbitMQ;

public class RabbitConsumer
{
    private readonly IConfiguration _configuration;
    private readonly IConnection _connection;
    private readonly IChannel _channel;

    public RabbitConsumer(IConfiguration configuration)
    {
        _configuration = configuration;

        ConnectionFactory connectionFactory = new()
        {
            HostName = "ais.rabbitmq", UserName = "guest", Password = "guest", VirtualHost = "/",
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
        var consumer = new AsyncEventingBasicConsumer(_channel);

        consumer.ReceivedAsync += async (sender, ea) =>
        {
            try
            {
                // Декодируем сообщение
                // var message = Encoding.UTF8.GetString(ea.Body.ToArray());
                var meal = JsonSerializer.Deserialize<MealMessage>(ea.Body.ToArray());
                Console.WriteLine($"Получено сообщение: {meal.Message}");

                // Подтверждаем
                await _channel.BasicAckAsync(ea.DeliveryTag, false);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка при обработке сообщения: {ex.Message}");
            }
        };

        await _channel.BasicConsumeAsync(queue: "meals-queue", autoAck: false, consumer: consumer);

        Console.WriteLine("Начато потребление сообщений...");
        await Task.CompletedTask;
    }
}

public class MealMessage
{
    public string Message { get; set; }
}

/*
{
    "Message": "Hello, World! From RabbitMQ"
}
*/
