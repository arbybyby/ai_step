using System.Text.Json;
using System.Threading.Channels;

using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace AIS.Infrastructure.RabbitMQ;

public class RabbitConsumer
{
    private IConnection? _connection;
    private IChannel? _channel;

    private readonly ILogger<RabbitConsumer> _logger;
    private readonly ChannelWriter<MealMessage> _addChannelWriter;
    private readonly ChannelWriter<DeleteMessage> _deleteChannelWriter;
    private readonly ChannelWriter<UserMessage> _userChannelWriter;
    private readonly ChannelWriter<AvatarURlMessage> _avatarChannelWriter;

    private readonly string _host;
    private readonly int _port;
    private readonly string _user;
    private readonly string _password;
    private readonly string _virtualHost;

    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    public RabbitConsumer(
        ChannelWriter<MealMessage> addChannelWriter,
        ILogger<RabbitConsumer> logger,
        IConfiguration configuration,
        ChannelWriter<DeleteMessage> deleteChannelWriter,
        ChannelWriter<UserMessage> userChannelWriter,
        ChannelWriter<AvatarURlMessage> avatarChannelWriter)
    {
        _logger = logger;
        _deleteChannelWriter = deleteChannelWriter;
        _userChannelWriter = userChannelWriter;
        _avatarChannelWriter = avatarChannelWriter;
        _addChannelWriter = addChannelWriter;

        _host = configuration["Broker:Host"] ?? "localhost";
        _port = int.TryParse(configuration["Broker:Port"], out var port) ? port : 5672;
        _user = configuration["Broker:User"] ?? "guest";
        _password = configuration["Broker:Password"] ?? "guest";
        _virtualHost = configuration["Broker:VirtualHost"] ?? "/";
    }

    public async Task Start(CancellationToken cancellationToken = default)
    {
        await EnsureConnectedAsync(cancellationToken);

        if (_channel is null)
            throw new InvalidOperationException("RabbitMQ channel wasn't initialized");

        AsyncEventingBasicConsumer addConsumer = new(_channel);
        addConsumer.ReceivedAsync += async (_, ea) =>
        {
            try
            {
                MealMessage? meal = JsonSerializer.Deserialize<MealMessage>(ea.Body.ToArray(), JsonOptions);
                if (meal is null)
                {
                    _logger.LogWarning("Add message deserialized to null");
                    await _channel.BasicNackAsync(ea.DeliveryTag, false, requeue: false, cancellationToken: cancellationToken);
                    return;
                }

                _logger.LogInformation("Received add message for MealID: {MealID}, UserID: {UserID}", meal.MealID,
                    meal.UserID);
                await _addChannelWriter.WriteAsync(meal, cancellationToken);
                await _channel.BasicAckAsync(ea.DeliveryTag, false, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing add message");
                await _channel.BasicNackAsync(ea.DeliveryTag, false, requeue: true, cancellationToken: cancellationToken);
            }
        };

        AsyncEventingBasicConsumer deleteConsumer = new(_channel);
        deleteConsumer.ReceivedAsync += async (_, ea) =>
        {
            try
            {
                DeleteMessage? message = JsonSerializer.Deserialize<DeleteMessage>(ea.Body.ToArray(), JsonOptions);
                if (message is null)
                {
                    _logger.LogWarning("Delete message deserialized to null");
                    await _channel.BasicNackAsync(ea.DeliveryTag, false, requeue: false, cancellationToken: cancellationToken);
                    return;
                }

                _logger.LogInformation("Received delete message for MealID: {MealID}, UserID: {UserID}", message.Id,
                    message.UserID);
                await _deleteChannelWriter.WriteAsync(message, cancellationToken);
                await _channel.BasicAckAsync(ea.DeliveryTag, false, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing delete message");
                await _channel.BasicNackAsync(ea.DeliveryTag, false, requeue: true, cancellationToken: cancellationToken);
            }
        };

        AsyncEventingBasicConsumer userConsumer = new(_channel);
        userConsumer.ReceivedAsync += async (_, ea) =>
        {
            try
            {
                UserMessage? user = JsonSerializer.Deserialize<UserMessage>(ea.Body.ToArray(), JsonOptions);
                if (user is null)
                {
                    _logger.LogWarning("User message deserialized to null");
                    await _channel.BasicNackAsync(ea.DeliveryTag, false, requeue: false, cancellationToken: cancellationToken);
                    return;
                }

                await _userChannelWriter.WriteAsync(user, cancellationToken);
                _logger.LogInformation("Received user with id {Id}", user.Id);
                await _channel.BasicAckAsync(ea.DeliveryTag, false, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing user message");
                await _channel.BasicNackAsync(ea.DeliveryTag, false, requeue: false, cancellationToken: cancellationToken);
            }
        };

        AsyncEventingBasicConsumer avatarConsumer = new(_channel);
        avatarConsumer.ReceivedAsync += async (_, ea) =>
        {
            try
            {
                AvatarURlMessage? avatarURl = JsonSerializer.Deserialize<AvatarURlMessage?>(ea.Body.ToArray());
                if (avatarURl is null)
                {
                    _logger.LogWarning("Avatar message deserialized to null");
                    await _channel.BasicNackAsync(ea.DeliveryTag, false, requeue: false, cancellationToken: cancellationToken);
                    return;
                }

                await _avatarChannelWriter.WriteAsync(avatarURl, cancellationToken);
                await _channel.BasicAckAsync(ea.DeliveryTag, false, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing avatar message");
                await _channel.BasicNackAsync(ea.DeliveryTag, false, requeue: false, cancellationToken: cancellationToken);
            }
        };

        await _channel.BasicConsumeAsync("meals.add.queue", autoAck: false, consumer: addConsumer,
            cancellationToken: cancellationToken);
        await _channel.BasicConsumeAsync("meals.delete.queue", autoAck: false, consumer: deleteConsumer,
            cancellationToken: cancellationToken);
        await _channel.BasicConsumeAsync("users.queue", autoAck: false, consumer: userConsumer,
            cancellationToken: cancellationToken);
    }

    private async Task EnsureConnectedAsync(CancellationToken cancellationToken)
    {
        if (_channel is not null)
            return;

        var connectionFactory = new ConnectionFactory
        {
            HostName = _host,
            Port = _port,
            UserName = _user,
            Password = _password,
            VirtualHost = _virtualHost,
            AutomaticRecoveryEnabled = true,
            NetworkRecoveryInterval = TimeSpan.FromSeconds(5)
        };

        const int maxAttempts = 30;
        for (var attempt = 1; attempt <= maxAttempts; attempt++)
        {
            cancellationToken.ThrowIfCancellationRequested();

            try
            {
                _logger.LogInformation(
                    "Connecting to RabbitMQ {Host}:{Port} vhost '{VHost}' (attempt {Attempt}/{MaxAttempts})",
                    _host, _port, _virtualHost, attempt, maxAttempts);

                _connection = await connectionFactory.CreateConnectionAsync(cancellationToken);
                _channel = await _connection.CreateChannelAsync(cancellationToken: cancellationToken);

                await InitializeTopologyAsync(cancellationToken);

                _logger.LogInformation("RabbitMQ connection established");
                return;
            }
            catch (Exception ex) when (attempt < maxAttempts)
            {
                var delay = TimeSpan.FromSeconds(Math.Min(30, Math.Pow(2, attempt / 4.0)));
                _logger.LogWarning(ex, "RabbitMQ connection failed. Retrying in {DelaySeconds:F1}s",
                    delay.TotalSeconds);
                await Task.Delay(delay, cancellationToken);
            }
        }

        throw new InvalidOperationException(
            $"Unable to connect to RabbitMQ at '{_host}:{_port}' after {maxAttempts} attempts");
    }

    private async Task InitializeTopologyAsync(CancellationToken cancellationToken)
    {
        if (_channel is null)
        {
            throw new InvalidOperationException("RabbitMQ channel wasn't initialized");
        }

        await _channel.ExchangeDeclareAsync("meals-exchange", ExchangeType.Topic, durable: true,
            cancellationToken: cancellationToken);
        await _channel.QueueDeclareAsync("meals.add.queue", durable: true, exclusive: false, autoDelete: false,
            arguments: null, cancellationToken: cancellationToken);
        await _channel.QueueDeclareAsync("meals.delete.queue", durable: true, exclusive: false, autoDelete: false,
            arguments: null, cancellationToken: cancellationToken);

        await _channel.ExchangeDeclareAsync("users.exchange", ExchangeType.Topic, durable: true,
            cancellationToken: cancellationToken);
        await _channel.QueueDeclareAsync("users.queue", durable: true, exclusive: false, autoDelete: false,
            arguments: null, cancellationToken: cancellationToken);

        await _channel.QueueBindAsync("meals.add.queue", "meals-exchange", "meals.add",
            cancellationToken: cancellationToken);
        await _channel.QueueBindAsync("meals.delete.queue", "meals-exchange", "meals.delete",
            cancellationToken: cancellationToken);
        await _channel.QueueBindAsync("users.queue", "users.exchange", "users.submit",
            cancellationToken: cancellationToken);

        await _channel.ExchangeDeclareAsync("avatars.exchange", ExchangeType.Topic, durable: true,
            cancellationToken: cancellationToken);

        await _channel.QueueBindAsync("avatars.queue", "avatars.exchange", "users.avatar",
            cancellationToken: cancellationToken);
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

public class UserMessage
{
    public int Id { get; init; }

    public string Email { get; init; }

    public string FirstName { get; init; }

    public string LastName { get; init; }

    public int Age { get; init; }

    public double Height { get; init; }

    public double Weight { get; init; }

    public int Gender { get; init; }

    public int ActivityLevel { get; init; }

    public int Goal { get; init; }

    public bool IsVerified { get; init; }

    public double CalorieGoal { get; init; }

    public double ProteinGoal { get; init; }

    public double WaterGoal { get; init; }

    public int StepsGoal { get; init; }
}

public class AvatarURlMessage
{
    public int UserID { get; init; }

    public string AvatarPath { get; init; }
}
