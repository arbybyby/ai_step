using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Infrastructure.Entities;

using Microsoft.EntityFrameworkCore;

namespace AIS.Infrastructure.Repositories;

public class AvatarRepository : IAvatarRepository
{
    private readonly AppDBContext _context;

    public AvatarRepository(AppDBContext context)
    {
        _context = context;
    }

    public async Task Save(AvatarURL avatarUrl)
    {
        AvatarURLEntity? entity = await _context.AvatarURLs.FindAsync(avatarUrl.UserID);
        if (entity == null)
        {
            await _context.AddAsync(MapToEntity(avatarUrl));
        }
        else
        {
            _context.Update(MapToEntity(avatarUrl));
        }
        await _context.SaveChangesAsync();
    }

    public async Task<AvatarURL?> Get(int userID)
    {
        var entity = await _context.AvatarURLs.FirstOrDefaultAsync(avatarUrl => avatarUrl.UserID == userID);
        return MapToDomain(entity);
    }

    private AvatarURLEntity MapToEntity(AvatarURL avatarUrl)
    {
        return new AvatarURLEntity() { UserID = avatarUrl.UserID, URL = avatarUrl.URL, };
    }

    private AvatarURL MapToDomain(AvatarURLEntity? avatarUrlEntity)
    {
        return new AvatarURL() { UserID = avatarUrlEntity.UserID, URL = avatarUrlEntity.URL, };
    }
}
