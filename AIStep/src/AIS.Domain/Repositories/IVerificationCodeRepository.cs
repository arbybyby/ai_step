using AIS.Domain.Models;

namespace AIS.Domain.Repositories;

public interface IVerificationCodeRepository
{
    Task<VerificationCode?> GetValidCodeAsync(string email, string code);
    
    Task AddAsync(VerificationCode verificationCode);
    
    Task UpdateAsync(VerificationCode verificationCode);
    
    Task SaveChangesAsync();
}
