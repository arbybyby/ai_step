using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Domain.Services;

namespace AIS.AdminPanel.Services;

public class AdminManageService : IAdminManageService
{
    private readonly IAdminRepository _adminRepository;
    private readonly IAdminAuthService _adminAuthService;

    public AdminManageService(IAdminRepository adminRepository, IAdminAuthService adminAuthService)
    {
        _adminRepository = adminRepository;
        _adminAuthService = adminAuthService;
    }

    public async Task<List<Admin>> GetAllAdminsAsync()
    {
        return await _adminRepository.GetAllAsync();
    }

    public async Task<Admin> CreateAdminAsync(string email, string password, string firstName, string lastName)
    {
        return await _adminAuthService.CreateAdminAsync(email, password, firstName, lastName);
    }

    public async Task DeleteAdminAsync(int id)
    {
        await _adminRepository.DeleteAsync(id);
    }
}

