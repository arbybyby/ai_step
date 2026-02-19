using AIS.Domain.Models;

namespace AIS.Domain.Repositories;

public interface IAvatarRepository
{
    public Task Save(AvatarURL avatarUrl);

    public Task<AvatarURL> Get(int userID);
}
