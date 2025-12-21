using AIS.Domain.Services;

using Microsoft.Extensions.Configuration;

using System.Net;
using System.Net.Mail;

namespace AIS.Database.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;

    public EmailService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public async Task SendEmailAsync(string to, string subject, string body)
    {
        var smtpHost = _configuration["Email:SmtpHost"] ?? "localhost";
        var smtpPort = int.Parse(_configuration["Email:SmtpPort"] ?? "1025");
        var fromEmail = _configuration["Email:From"] ?? "noreply@test.com";
        var password = _configuration["Email:Password"] ?? string.Empty;

        using var client = new SmtpClient(smtpHost, smtpPort)
        {
            // MailHog не требует аутентификации
            Credentials = string.IsNullOrEmpty(password)
                ? null
                : new NetworkCredential(fromEmail, password),
            EnableSsl = false, // MailHog не использует SSL
            DeliveryMethod = SmtpDeliveryMethod.Network,
            UseDefaultCredentials = false
        };

        var mailMessage = new MailMessage
        {
            From = new MailAddress(fromEmail, "AI Step"),
            Subject = subject,
            Body = body,
            IsBodyHtml = true
        };

        mailMessage.To.Add(new MailAddress(to));

        try
        {
            await client.SendMailAsync(mailMessage);
        }
        catch (SmtpException ex)
        {
            throw new InvalidOperationException(
                $"Failed to send email via {smtpHost}:{smtpPort}. {ex.Message}", ex);
        }
    }

    public async Task SendVerificationCodeAsync(string to, string code)
    {
        var subject = "Verification Code";
        var body = $@"
            <html>
            <body style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;'>
                <div style='background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 10px; color: white;'>
                    <h2 style='margin: 0;'>Welcome to AI Step!</h2>
                </div>
                <div style='background: #f7f7f7; padding: 30px; border-radius: 10px; margin-top: 20px;'>
                    <p style='font-size: 16px; color: #333;'>Your verification code:</p>
                    <div style='background: white; padding: 20px; border-radius: 5px; text-align: center; margin: 20px 0;'>
                        <span style='font-size: 32px; font-weight: bold; color: #667eea; letter-spacing: 5px;'>{code}</span>
                    </div>
                    <p style='color: #666; font-size: 14px;'>
                        ⏱️ This code is valid for <strong>10 minutes</strong>.
                    </p>
                    <p style='color: #999; font-size: 12px; margin-top: 30px;'>
                        If you did not sign up for an account, please ignore this email.
                    </p>
                </div>
            </body>
            </html>";

        await SendEmailAsync(to, subject, body);
    }
}
