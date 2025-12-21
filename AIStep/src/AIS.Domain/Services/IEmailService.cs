namespace AIS.Domain.Services;

public interface IEmailService
{
    Task SendEmailAsync(string to, string subject, string body);
    
    Task SendVerificationCodeAsync(string to, string code);
}
