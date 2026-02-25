using AIS.Domain.Models;
using AIS.Domain.Repositories;

namespace AIS.AdminPanel.Services;

public class UserAdminService : IUserAdminService
{
    private readonly IUserRepository _userRepository;

    public UserAdminService(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<List<User>> GetAllUsersAsync()
    {
        return await _userRepository.GetAllAsync();
    }

    public async Task<User> GetUserAsync(int id)
    {
        var user = await _userRepository.GetByIdAsync(id);
        if (user == null)
            throw new KeyNotFoundException($"Пользователь с ID {id} не найден");
        return user;
    }

    public async Task UpdateUserAsync(User user)
    {
        await _userRepository.UpdateAsync(user);
    }

    public async Task DeleteUserAsync(int id)
    {
        await _userRepository.DeleteAsync(id);
    }
}

