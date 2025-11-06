using AP.Domain;
using AP.Domain.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AP.Database.Repositories;

public class UserRepository : IUserRepository
{
    private readonly IDbContextFactory<AppDbContext> _contextFactory;
    private readonly ILogger<UserRepository> _logger;

    public UserRepository(IDbContextFactory<AppDbContext> contextFactory, ILogger<UserRepository> logger)
    {
        _contextFactory = contextFactory;
        _logger = logger;
    }

    public void DeleteById(long id)
    {
        using var dbContext = _contextFactory.CreateDbContext();
        var userEntity = dbContext.Users.Find(id);
        if (userEntity != null)
        {
            dbContext.Remove(userEntity);
            dbContext.SaveChanges();
            _logger.LogInformation("Deleted user with ID {UserId}", id);
        }
        else
        {
            _logger.LogWarning("User with ID {UserId} not found for deletion", id);
        }
    }

    public List<User> GetAll()
    {
        _logger.LogInformation("Attempting to connect to database...");

        try
        {
            _logger.LogInformation("Database connection successful");

            using var dbContext = _contextFactory.CreateDbContext();
            var userCount = dbContext.Users.Count();
            _logger.LogInformation("Total user entities in database: {UserCount}", userCount);

            var users = dbContext.Users
                .AsNoTracking()
                .Select(userEntity => userEntity.ToDomain())
                .ToList();

            _logger.LogInformation("Retrieved {UserCount} users from the database.", users.Count);

            return users;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving users from database");
            throw;
        }
    }

    public User? GetById(long id)
    {
        using var dbContext = _contextFactory.CreateDbContext();
        var userEntity = dbContext.Users.AsNoTracking().FirstOrDefault(u => u.Id == id);

        return userEntity?.ToDomain();
    }
}
