using AIS.Domain.Models;

namespace AIS.Domain.Repositories;

public interface IUserRepository
{
    Task<User?> GetByEmailAsync(string email);
    
    Task<User?> GetByIdAsync(int id);
    
    Task<bool> ExistsAsync(string email);
    
    Task AddAsync(User user);
    
    Task UpdateAsync(User user);
    
    Task SaveChangesAsync();
}
