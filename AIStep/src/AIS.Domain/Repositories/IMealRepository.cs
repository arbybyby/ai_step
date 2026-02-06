using AIS.Domain.Models;

namespace AIS.Domain.Repositories;

public interface IMealRepository
{
    void Add(Meal meal);

    void Remove(int mealId);
}
