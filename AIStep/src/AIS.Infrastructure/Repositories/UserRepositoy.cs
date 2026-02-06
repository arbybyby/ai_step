using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Infrastructure.Entities;

using Microsoft.EntityFrameworkCore;

namespace AIS.Infrastructure.Repositories;

public class UserRepository : IUserRepository
{
    private readonly AppDBContext _context;

    public UserRepository(AppDBContext context)
    {
        _context = context;
    }

    public async Task<User?> GetByEmailAsync(string email)
    {
        var entity = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
        return entity == null ? null : MapToUser(entity);
    }

    public async Task<User?> GetByIdAsync(int id)
    {
        var entity = await _context.Users.FindAsync(id);
        return entity == null ? null : MapToUser(entity);
    }

    public async Task<bool> ExistsAsync(string email)
    {
        return await _context.Users.AnyAsync(u => u.Email == email);
    }

    public async Task AddAsync(User user)
    {
        var entity = MapToEntity(user);
        await _context.Users.AddAsync(entity);
    }

    public async Task UpdateAsync(User user)
    {
        var entity = await _context.Users.FindAsync(user.ID);
        if (entity != null)
        {
            entity.Email = user.Email;
            entity.FirstName = user.FirstName;
            entity.LastName = user.LastName;
            entity.IsVerified = user.IsVerified;
            entity.WeightKg = user.WeightKg;
            entity.HeightCm = user.HeightCm;
            entity.CreatedAt = user.CreatedAt;

            _context.Users.Update(entity);
        }
        await Task.CompletedTask;
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }

    public async Task<UserEntity?> GetEntityByEmailAsync(string email)
    {
        return await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
    }

    public async Task AddEntityAsync(UserEntity entity)
    {
        await _context.Users.AddAsync(entity);
    }

    private User MapToUser(UserEntity entity)
    {
        return new User
        {
            ID = entity.ID,
            Email = entity.Email,
            FirstName = entity.FirstName,
            LastName = entity.LastName,
            WeightKg = entity.WeightKg,
            HeightCm = entity.HeightCm,
            IsVerified = entity.IsVerified,
            CreatedAt = entity.CreatedAt
        };
    }

    private UserEntity MapToEntity(User user)
    {
        return new UserEntity
        {
            ID = user.ID,
            Email = user.Email,
            FirstName = user.FirstName,
            LastName = user.LastName,
            WeightKg = user.WeightKg,
            HeightCm = user.HeightCm,
            IsVerified = user.IsVerified,
            CreatedAt = user.CreatedAt,
            PasswordHash = string.Empty
        };
    }
}
