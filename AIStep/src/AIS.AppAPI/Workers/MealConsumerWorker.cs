using System.Threading.Channels;

using AIS.Domain.Factories;
using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Infrastructure.RabbitMQ;

namespace AIS.AppAPI.Workers;

public class MealConsumerWorker : BackgroundService
{
    private readonly ChannelReader<MealMessage?> _mealReader;
    private readonly ChannelReader<DeleteMessage> _deleteReader;
    private readonly ChannelReader<UserMessage?> _userReader;
    private readonly IServiceScopeFactory _serviceScopeFactory;
    private readonly RabbitConsumer _consumer;
    private readonly ILogger<MealConsumerWorker> _logger;

    public MealConsumerWorker(
        RabbitConsumer consumer,
        ChannelReader<MealMessage?> mealReader,
        IServiceScopeFactory serviceScopeFactory,
        ChannelReader<DeleteMessage> deleteReader,
        ILogger<MealConsumerWorker> logger,
        ChannelReader<UserMessage?> userReader)
    {
        _consumer = consumer;
        _mealReader = mealReader;
        _serviceScopeFactory = serviceScopeFactory;
        _deleteReader = deleteReader;
        _logger = logger;
        _userReader = userReader;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await _consumer.Start(stoppingToken);
                break;
            }
            catch (Exception ex) when (!stoppingToken.IsCancellationRequested)
            {
                _logger.LogWarning(ex, "RabbitMQ consumer start failed. Retrying in 5s...");
                await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
            }
        }

        var mealTask = ProcessMealMessages(stoppingToken);
        var deleteTask = ProcessDeleteMessages(stoppingToken);
        var userTask = ProcessUserMessage(stoppingToken);

        await Task.WhenAll(mealTask, deleteTask, userTask);
    }

    private async Task ProcessMealMessages(CancellationToken stoppingToken)
    {
        await foreach (MealMessage? meal in _mealReader.ReadAllAsync(stoppingToken))
        {
            if (meal is not null)
            {
                using var scope = _serviceScopeFactory.CreateScope();
                var userMealRepository = scope.ServiceProvider.GetRequiredService<IUserMealRepository>();
                var userMealFactory = scope.ServiceProvider.GetRequiredService<UserMealFactory>();

                UserMeal userMeal =
                    await userMealFactory.Create(meal.UserID, meal.MealID, meal.MealType, meal.Grammes, meal.Date);
                await userMealRepository.Add(userMeal);
            }
        }
    }

    private async Task ProcessDeleteMessages(CancellationToken stoppingToken)
    {
        await foreach (DeleteMessage? message in _deleteReader.ReadAllAsync(stoppingToken))
        {
            using var scope = _serviceScopeFactory.CreateScope();
            var userMealRepository = scope.ServiceProvider.GetRequiredService<IUserMealRepository>();

            await userMealRepository.Remove(message.Id);
        }
    }

    // `src/AIS.AppAPI/Workers/MealConsumerWorker.cs`
    private async Task ProcessUserMessage(CancellationToken stoppingToken)
    {
        await foreach (UserMessage? message in _userReader.ReadAllAsync(stoppingToken))
        {
            if (message is null)
            {
                _logger.LogWarning("Received null UserMessage");
                continue;
            }

            if (message.Id <= 0)
            {
                _logger.LogWarning("Invalid UserMessage.Id={Id}. Skipping update.", message.Id);
                continue;
            }
            _logger.LogInformation("ID: {UserID}",message.Id);

            try
            {
                using var scope = _serviceScopeFactory.CreateScope();
                var userRepository = scope.ServiceProvider.GetRequiredService<IUserRepository>();
                var gender = Enum.IsDefined(typeof(Gender), message.Gender)
                    ? (Gender)message.Gender
                    : default;

                var activityLevel = Enum.IsDefined(typeof(ActivityLevel), message.ActivityLevel)
                    ? (ActivityLevel)message.ActivityLevel
                    : default;

                var goal = Enum.IsDefined(typeof(FitnessGoal), message.Goal)
                    ? (FitnessGoal)message.Goal
                    : default;
                var user = new User
                {
                    ID = message.Id,
                    Email = message.Email,
                    FirstName = message.FirstName,
                    LastName = message.LastName,
                    HeightCm = message.Height,
                    WeightKg = message.Weight,
                    Age = message.Age,

                    // map the rest of fields if they exist in UserMessage
                    Gender = gender,
                    FitnessGoal = goal,
                    ActivityLevel = activityLevel,
                    IsVerified = message.IsVerified
                };

                await userRepository.UpdateAsync(user);
            }
            catch (Exception ex) when (!stoppingToken.IsCancellationRequested)
            {
                _logger.LogError(ex, "Failed to process UserMessage: Id={Id}", message.Id);
            }
        }
    }

}
