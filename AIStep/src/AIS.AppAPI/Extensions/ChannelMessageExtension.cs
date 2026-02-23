using System.Threading.Channels;

using AIS.Infrastructure.RabbitMQ;

namespace AIS.AppAPI.Extensions;

public static class ChannelMessageExtension
{
    public static IServiceCollection AddChannelMessage(this IServiceCollection services)
    {
        Channel<MealMessage> channel = Channel.CreateUnbounded<MealMessage>();
        services.AddSingleton(channel.Writer);
        services.AddSingleton(channel.Reader);

        Channel<DeleteMessage>  channelDelete = Channel.CreateUnbounded<DeleteMessage>();
        services.AddSingleton(channelDelete.Reader);
        services.AddSingleton(channelDelete.Writer);

        Channel<UserMessage> userChannel = Channel.CreateUnbounded<UserMessage>();
        services.AddSingleton(userChannel.Reader);
        services.AddSingleton(userChannel.Writer);

        Channel<AvatarURlMessage> avatarChannel = Channel.CreateUnbounded<AvatarURlMessage>();
        services.AddSingleton(avatarChannel.Reader);
        services.AddSingleton(avatarChannel.Writer);

        return services;
    }
}
