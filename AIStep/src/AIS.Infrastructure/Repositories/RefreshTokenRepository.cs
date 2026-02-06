using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Infrastructure.Entities;

using Microsoft.EntityFrameworkCore;

namespace AIS.Infrastructure.Repositories;

public class RefreshTokenRepository : IRefreshTokenRepository
{
    private readonly AppDBContext _context;

    public RefreshTokenRepository(AppDBContext context)
    {
        _context = context;
    }

    public async Task<RefreshToken?> GetByTokenAsync(string token)
    {
        var entity = await _context.RefreshTokens
            .Include(rt => rt.User)
            .FirstOrDefaultAsync(rt => rt.Token == token);
        
        return entity == null ? null : MapToRefreshToken(entity);
    }

    public async Task AddAsync(RefreshToken refreshToken)
    {
        var entity = MapToEntity(refreshToken);
        await _context.RefreshTokens.AddAsync(entity);
    }

    public async Task UpdateAsync(RefreshToken refreshToken)
    {
        var entity = await _context.RefreshTokens.FindAsync(refreshToken.ID);
        if (entity != null)
        {
            entity.UserId = refreshToken.UserId;
            entity.Token = refreshToken.Token;
            entity.CreatedAt = refreshToken.CreatedAt;
            entity.ExpiresAt = refreshToken.ExpiresAt;
            entity.IsRevoked = refreshToken.IsRevoked;
            entity.ReplacedByToken = refreshToken.ReplacedByToken;
            _context.RefreshTokens.Update(entity);
        }
        await Task.CompletedTask;
    }

    public async Task<List<RefreshToken>> GetActiveTokensByUserIdAsync(int userId)
    {
        var entities = await _context.RefreshTokens
            .Where(rt => rt.UserId == userId && !rt.IsRevoked && rt.ExpiresAt > DateTime.UtcNow)
            .ToListAsync();
        
        return entities.Select(MapToRefreshToken).ToList();
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }

    private RefreshToken MapToRefreshToken(RefreshTokenEntity entity)
    {
        return new RefreshToken
        {
            ID = entity.ID,
            UserId = entity.UserId,
            Token = entity.Token,
            CreatedAt = entity.CreatedAt,
            ExpiresAt = entity.ExpiresAt,
            IsRevoked = entity.IsRevoked,
            ReplacedByToken = entity.ReplacedByToken
        };
    }

    private RefreshTokenEntity MapToEntity(RefreshToken token)
    {
        return new RefreshTokenEntity
        {
            ID = token.ID,
            UserId = token.UserId,
            Token = token.Token,
            CreatedAt = token.CreatedAt,
            ExpiresAt = token.ExpiresAt,
            IsRevoked = token.IsRevoked,
            ReplacedByToken = token.ReplacedByToken
        };
    }
}
