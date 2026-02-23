using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Infrastructure.Entities;
using Microsoft.EntityFrameworkCore;

namespace AIS.Infrastructure.Repositories;

public class AdminRepository : IAdminRepository
{
    private readonly AppDBContext _context;

    public AdminRepository(AppDBContext context)
    {
        _context = context;
    }

    public async Task<Admin?> GetByEmailAsync(string email)
    {
        var entity = await _context.Admins.FirstOrDefaultAsync(a => a.Email == email);
        return entity == null ? null : MapToAdmin(entity);
    }

    public async Task<Admin?> GetByIdAsync(int id)
    {
        var entity = await _context.Admins.FindAsync(id);
        return entity == null ? null : MapToAdmin(entity);
    }

    public async Task<Admin> CreateAsync(Admin admin, string passwordHash)
    {
        var entity = new AdminEntity
        {
            Email = admin.Email,
            FirstName = admin.FirstName,
            LastName = admin.LastName,
            PasswordHash = passwordHash,
            CreatedAt = DateTime.UtcNow
        };

        await _context.Admins.AddAsync(entity);
        await _context.SaveChangesAsync();

        admin.Id = entity.ID;
        return admin;
    }

    public async Task<bool> ValidatePasswordAsync(string email, string password)
    {
        var entity = await _context.Admins.FirstOrDefaultAsync(a => a.Email == email);
        if (entity == null)
        {
            return false;
        }

        return BCrypt.Net.BCrypt.Verify(password, entity.PasswordHash);
    }

    public async Task<List<Admin>> GetAllAsync()
    {
        var entities = await _context.Admins.ToListAsync();
        return entities.Select(MapToAdmin).ToList();
    }

    private Admin MapToAdmin(AdminEntity entity)
    {
        return new Admin
        {
            Id = entity.ID,
            Email = entity.Email,
            FirstName = entity.FirstName,
            LastName = entity.LastName
        };
    }
}

