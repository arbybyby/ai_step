using AIS.Domain.Models;

namespace AIS.AdminPanel.Services;

public interface IAdminManageService
{
    Task<List<Admin>> GetAllAdminsAsync();
    Task<Admin> CreateAdminAsync(string email, string password, string firstName, string lastName);
    Task DeleteAdminAsync(int id);
}

