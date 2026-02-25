using AIS.Domain.Models;

namespace AIS.AdminPanel.Services;

public interface IUserAdminService
{
    Task<List<User>> GetAllUsersAsync();
    Task<User> GetUserAsync(int id);
    Task UpdateUserAsync(User user);
    Task DeleteUserAsync(int id);
}

