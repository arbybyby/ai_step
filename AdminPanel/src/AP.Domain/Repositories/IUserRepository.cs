namespace AP.Domain.Repositories;

public interface IUserRepository 
{
    public List<User> GetAll();

    public User? GetById(long id);

    public void DeleteById(long id);
}
