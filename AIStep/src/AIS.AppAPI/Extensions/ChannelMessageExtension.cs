using System.Threading.Channels;

using AIS.Infrastructure.RabbitMQ;

namespace AIS.AppAPI.Extensions;

public static class ChannelMessageExtension
{
    public static IServiceCollection AddChannelMessage(this IServiceCollection services)
    {
        Channel<MealMessage?> channel = Channel.CreateUnbounded<MealMessage?>();

        services.AddSingleton(channel.Writer);
        services.AddSingleton(channel.Reader);

        return services;
    }
}
