using AIS.Domain.Models;
using AIS.Domain.Repositories;

using Microsoft.Extensions.Logging;

namespace AIS.Infrastructure.Repositories;

public class MealRepository : IMealRepository
{
    private readonly AppDBContext _context;
    private readonly ILogger<MealRepository> _logger;

    public MealRepository(AppDBContext context, ILogger<MealRepository> logger)
    {
        _context = context;
        _logger = logger;
    }

    public void Add(Meal meal)
    {
        throw new NotImplementedException();
    }

    public void Remove(int mealId)
    {
        throw new NotImplementedException();
    }
}
