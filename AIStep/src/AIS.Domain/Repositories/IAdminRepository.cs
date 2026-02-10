using AIS.Domain.Models;

namespace AIS.Domain.Repositories;

public interface IAdminRepository
{
    Task<Admin?> GetByIdAsync(int id);
    Task<Admin?> GetByEmailAsync(string email);
    Task<Admin> CreateAsync(Admin admin, string passwordHash);
    Task<bool> ValidatePasswordAsync(string email, string password);
    Task<List<Admin>> GetAllAsync();
}

