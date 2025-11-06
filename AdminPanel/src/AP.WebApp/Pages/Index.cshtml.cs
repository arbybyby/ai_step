using AP.Domain;
using AP.Domain.Repositories;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Threading.Tasks;

namespace AP.WebApp.Pages
{
    public class IndexModel : PageModel
    {
        private readonly ILogger<IndexModel> _logger;
        private readonly IUserRepository _userRepository;
        private readonly IStepRepository _stepsRepository;

        public List<User> Users { get; set; } = [];
        public List<DailyStepsResult> DailyStepsResults { get; set; } = [];
        public string SortOrder { get; set; } = "steps_asc";

        public IndexModel(IUserRepository userRepository, IStepRepository stepsRepository, ILogger<IndexModel> logger)
        {
            _userRepository = userRepository;
            _logger = logger;
            _stepsRepository = stepsRepository;
        }

        public void OnGet(string sortOrder = "steps_asc")
        {
            SortOrder = sortOrder;
            LoadUsers();
        }

        public IActionResult OnPostDelete(long userId)
        {
            try
            {
                _userRepository.DeleteById(userId);
                _logger.LogInformation("User with ID {UserId} deleted successfully.", userId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting user with ID {UserId}", userId);
            }

            return RedirectToPage();
        }

        private void LoadUsers()
        {
            Users = _userRepository.GetAll();
            _logger.LogInformation(_logger.IsEnabled(LogLevel.Information)
                ? "OnGet executed. Retrieved {UserCount} users." 
                : "OnGet executed.", Users.Count);

            foreach (var user in Users)
            {
                LoadDailyStepsResults(user.Id).GetAwaiter().GetResult();
            }

            SortUsers();
        }

        private void SortUsers()
        {
            Users = SortOrder switch
            {
                "steps_desc" => Users
                    .OrderByDescending(u => DailyStepsResults.FirstOrDefault(d => d.UserId == u.Id)?.TotalSteps ?? 0)
                    .ToList(),
                _ => Users
                    .OrderBy(u => DailyStepsResults.FirstOrDefault(d => d.UserId == u.Id)?.TotalSteps ?? 0)
                    .ToList()
            };
        }

        private async Task LoadDailyStepsResults(long userId)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var result = await _stepsRepository.GetDailyStepsAsync(userId, today);
            _logger.LogInformation("Loaded daily steps for user ID {UserId} - {Id}: {TotalSteps} steps.", userId, result.UserId, result.TotalSteps);
            DailyStepsResults.Add(result);
        }
    }
}
