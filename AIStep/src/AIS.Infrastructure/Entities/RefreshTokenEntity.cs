﻿using System.ComponentModel.DataAnnotations;

namespace AIS.Infrastructure.Entities;

public class RefreshTokenEntity
{
    [Key]
    public int ID { get; set; }

    public int? UserId { get; set; }

    public int? AdminId { get; set; }

    public string Token { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime ExpiresAt { get; set; }

    public bool IsRevoked { get; set; }

    public string? ReplacedByToken { get; set; }

    public UserEntity? User { get; set; }

    public AdminEntity? Admin { get; set; }
}
