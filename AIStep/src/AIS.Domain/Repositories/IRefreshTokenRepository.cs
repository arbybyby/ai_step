using AIS.Domain.Models;

namespace AIS.Domain.Repositories;

public interface IRefreshTokenRepository
{
    Task<RefreshToken?> GetByTokenAsync(string token);
    
    Task AddAsync(RefreshToken refreshToken);
    
    Task UpdateAsync(RefreshToken refreshToken);
    
    Task<List<RefreshToken>> GetActiveTokensByUserIdAsync(int userId);
    
    Task SaveChangesAsync();
}
