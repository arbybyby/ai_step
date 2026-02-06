using AIS.Domain.Models;
using AIS.Domain.Repositories;
using AIS.Infrastructure.Entities;

using Microsoft.EntityFrameworkCore;

namespace AIS.Infrastructure.Repositories;

public class VerificationCodeRepository : IVerificationCodeRepository
{
    private readonly AppDBContext _context;

    public VerificationCodeRepository(AppDBContext context)
    {
        _context = context;
    }

    public async Task<VerificationCode?> GetValidCodeAsync(string email, string code)
    {
        var now = DateTime.UtcNow;
        var entity = await _context.VerificationCodes
            .FirstOrDefaultAsync(vc => 
                vc.Email == email && 
                vc.Code == code && 
                !vc.IsUsed && 
                vc.ExpiresAt > now);
        
        return entity == null ? null : MapToVerificationCode(entity);
    }

    public async Task AddAsync(VerificationCode verificationCode)
    {
        var entity = MapToEntity(verificationCode);
        await _context.VerificationCodes.AddAsync(entity);
    }

    public async Task UpdateAsync(VerificationCode verificationCode)
    {
        var entity = await _context.VerificationCodes.FindAsync(verificationCode.ID);
        if (entity != null)
        {
            entity.Email = verificationCode.Email;
            entity.Code = verificationCode.Code;
            entity.CreatedAt = verificationCode.CreatedAt;
            entity.ExpiresAt = verificationCode.ExpiresAt;
            entity.IsUsed = verificationCode.IsUsed;
            _context.VerificationCodes.Update(entity);
        }
        await Task.CompletedTask;
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }

    private VerificationCode MapToVerificationCode(VerificationCodeEntity entity)
    {
        return new VerificationCode
        {
            ID = entity.ID,
            Email = entity.Email,
            Code = entity.Code,
            CreatedAt = entity.CreatedAt,
            ExpiresAt = entity.ExpiresAt,
            IsUsed = entity.IsUsed
        };
    }

    private VerificationCodeEntity MapToEntity(VerificationCode code)
    {
        return new VerificationCodeEntity
        {
            ID = code.ID,
            Email = code.Email,
            Code = code.Code,
            CreatedAt = code.CreatedAt,
            ExpiresAt = code.ExpiresAt,
            IsUsed = code.IsUsed
        };
    }
}
