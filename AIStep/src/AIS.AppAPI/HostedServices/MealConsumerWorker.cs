using System.Threading.Channels;

using AIS.Domain.Factories;
using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Infrastructure.RabbitMQ;

namespace AIS.AppAPI.HostedServices;

public class MealConsumerWorker : BackgroundService
{
    private readonly ChannelReader<MealMessage?> _mealReader;
    private readonly ChannelReader<DeleteMessage> _deleteReader;
    private readonly IServiceScopeFactory _serviceScopeFactory;
    private readonly RabbitConsumer _consumer;

    public MealConsumerWorker(RabbitConsumer consumer,
        ChannelReader<MealMessage?> mealReader, IServiceScopeFactory serviceScopeFactory,
        ChannelReader<DeleteMessage> deleteReader)
    {
        _consumer = consumer;
        _mealReader = mealReader;
        _serviceScopeFactory = serviceScopeFactory;
        _deleteReader = deleteReader;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await _consumer.Start();

        var mealTask = ProcessMealMessages(stoppingToken);
        var deleteTask = ProcessDeleteMessages(stoppingToken);

        await Task.WhenAll(mealTask, deleteTask);
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
}
