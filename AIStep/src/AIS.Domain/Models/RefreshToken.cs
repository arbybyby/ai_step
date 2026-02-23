﻿namespace AIS.Domain.Models;

public class RefreshToken
{
    public int ID { get; set; }

    public int? UserId { get; set; }

    public int? AdminId { get; set; }

    public string Token { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }

    public DateTime ExpiresAt { get; set; }

    public bool IsRevoked { get; set; }

    public string? ReplacedByToken { get; set; }
}
