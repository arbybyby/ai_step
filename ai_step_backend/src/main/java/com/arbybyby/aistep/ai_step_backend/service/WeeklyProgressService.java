package com.arbybyby.aistep.ai_step_backend.service;

import com.arbybyby.aistep.ai_step_backend.dto.WeeklyProgressResponse;
import com.arbybyby.aistep.ai_step_backend.models.WeeklyProgress;
import com.arbybyby.aistep.ai_step_backend.repositories.StepsRepository;
import com.arbybyby.aistep.ai_step_backend.repositories.WeeklyProgressRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class WeeklyProgressService {

    @Autowired
    private WeeklyProgressRepository weeklyProgressRepository;

    @Autowired
    private StepsRepository stepsRepository;

    private static final int DEFAULT_DAILY_GOAL = 10000; // Default step goal

    /**
     * Calculate and save/update weekly progress for a specific week
     */
    @Transactional
    public WeeklyProgress calculateAndSaveWeeklyProgress(Long userId, LocalDate dateInWeek) {
        // Get Monday and Sunday of the week
        LocalDate weekStart = dateInWeek.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        LocalDate weekEnd = dateInWeek.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY));

        System.out.println("📊 Calculating weekly progress for user " + userId);
        System.out.println("   Week: " + weekStart + " to " + weekEnd);

        // Get or create weekly progress record
        WeeklyProgress weeklyProgress = weeklyProgressRepository
                .findByUserIdAndWeekStartDate(userId, weekStart)
                .orElse(new WeeklyProgress(userId, weekStart, weekEnd));

        // Calculate totals from daily data
        Map<String, Object> weeklyStats = calculateWeeklyStatistics(userId, weekStart, weekEnd);

        // Update weekly progress with calculated data
        weeklyProgress.setTotalSteps((Integer) weeklyStats.get("totalSteps"));
        weeklyProgress.setTotalDistanceM((Double) weeklyStats.get("totalDistanceM"));
        weeklyProgress.setTotalCalories((Double) weeklyStats.get("totalCalories"));
        weeklyProgress.setDailyAverageSteps((Integer) weeklyStats.get("averageSteps"));
        weeklyProgress.setGoalDaysCount((Integer) weeklyStats.get("goalDaysCount"));
        weeklyProgress.setBestDaySteps((Integer) weeklyStats.get("bestDaySteps"));
        weeklyProgress.setBestDayDate((LocalDate) weeklyStats.get("bestDayDate"));

        WeeklyProgress saved = weeklyProgressRepository.save(weeklyProgress);
        
        System.out.println("✅ Saved weekly progress: " + saved);
        
        return saved;
    }

    /**
     * Calculate weekly statistics from daily step data
     */
    private Map<String, Object> calculateWeeklyStatistics(Long userId, LocalDate weekStart, LocalDate weekEnd) {
        Map<String, Object> stats = new HashMap<>();

        // Get all daily data for the week
        List<Map<String, Object>> dailyData = stepsRepository
                .findStepHistoryByDateRange(userId, weekStart, weekEnd);

        System.out.println("   Found " + dailyData.size() + " days with data");

        int totalSteps = 0;
        double totalDistanceM = 0.0;
        double totalCalories = 0.0;
        int goalDaysCount = 0;
        int bestDaySteps = 0;
        LocalDate bestDayDate = null;

        for (Map<String, Object> dayData : dailyData) {
            int daySteps = ((Number) dayData.getOrDefault("totalSteps", 0)).intValue();
            double dayDistanceM = ((Number) dayData.getOrDefault("totalDistanceM", 0.0)).doubleValue();
            double dayCalories = ((Number) dayData.getOrDefault("totalCaloriesBurned", 0.0)).doubleValue();
            LocalDate date = (LocalDate) dayData.get("date");

            totalSteps += daySteps;
            totalDistanceM += dayDistanceM;
            totalCalories += dayCalories;

            if (daySteps >= DEFAULT_DAILY_GOAL) {
                goalDaysCount++;
            }

            if (daySteps > bestDaySteps) {
                bestDaySteps = daySteps;
                bestDayDate = date;
            }
        }

        int averageSteps = dailyData.isEmpty() ? 0 : totalSteps / 7; // Always calculate for 7 days

        stats.put("totalSteps", totalSteps);
        stats.put("totalDistanceM", totalDistanceM);
        stats.put("totalCalories", totalCalories);
        stats.put("averageSteps", averageSteps);
        stats.put("goalDaysCount", goalDaysCount);
        stats.put("bestDaySteps", bestDaySteps);
        stats.put("bestDayDate", bestDayDate);

        System.out.println("   Weekly stats: " + totalSteps + " steps, " + 
                         goalDaysCount + " goal days, best: " + bestDaySteps);

        return stats;
    }

    /**
     * Get weekly progress for current week
     */
    public WeeklyProgressResponse getCurrentWeekProgress(Long userId) {
        LocalDate today = LocalDate.now();
        WeeklyProgress progress = calculateAndSaveWeeklyProgress(userId, today);
        return convertToResponse(progress);
    }

    /**
     * Get weekly progress for a specific week
     */
    public WeeklyProgressResponse getWeekProgress(Long userId, LocalDate dateInWeek) {
        WeeklyProgress progress = calculateAndSaveWeeklyProgress(userId, dateInWeek);
        return convertToResponse(progress);
    }

    /**
     * Get last N weeks of progress
     */
    public List<WeeklyProgressResponse> getLastNWeeks(Long userId, int numberOfWeeks) {
        System.out.println("📅 Getting last " + numberOfWeeks + " weeks for user " + userId);
        
        List<WeeklyProgress> progressList = new ArrayList<>();
        LocalDate currentWeekDate = LocalDate.now();

        // Calculate and save progress for each of the last N weeks
        for (int i = 0; i < numberOfWeeks; i++) {
            LocalDate weekDate = currentWeekDate.minusWeeks(i);
            WeeklyProgress progress = calculateAndSaveWeeklyProgress(userId, weekDate);
            progressList.add(progress);
        }

        return progressList.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get weekly progress within a date range
     */
    public List<WeeklyProgressResponse> getWeeklyProgressInRange(Long userId, LocalDate startDate, LocalDate endDate) {
        List<WeeklyProgress> progressList = weeklyProgressRepository
                .findByUserIdAndDateRange(userId, startDate, endDate);
        
        return progressList.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get all weekly progress for a user
     */
    public List<WeeklyProgressResponse> getAllWeeklyProgress(Long userId) {
        List<WeeklyProgress> progressList = weeklyProgressRepository
                .findByUserIdOrderByWeekStartDateDesc(userId);
        
        return progressList.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get weekly statistics summary
     */
    public Map<String, Object> getWeeklyStatisticsSummary(Long userId, int numberOfWeeks) {
        LocalDate startDate = LocalDate.now().minusWeeks(numberOfWeeks);
        Object[] stats = weeklyProgressRepository.getWeeklyStatistics(userId, startDate);

        Map<String, Object> summary = new HashMap<>();
        if (stats != null && stats.length >= 4) {
            summary.put("weeksCount", ((Number) stats[0]).intValue());
            summary.put("averageWeeklySteps", ((Number) stats[1]).doubleValue());
            summary.put("bestWeekSteps", ((Number) stats[2]).intValue());
            summary.put("totalSteps", ((Number) stats[3]).longValue());
        } else {
            summary.put("weeksCount", 0);
            summary.put("averageWeeklySteps", 0.0);
            summary.put("bestWeekSteps", 0);
            summary.put("totalSteps", 0L);
        }
        
        summary.put("period", numberOfWeeks + " weeks");
        return summary;
    }

    /**
     * Recalculate all weekly progress for a user (useful for data migration or fixes)
     */
    @Transactional
    public void recalculateAllWeeklyProgress(Long userId, LocalDate startDate, LocalDate endDate) {
        System.out.println("🔄 Recalculating all weekly progress for user " + userId);
        System.out.println("   From: " + startDate + " to: " + endDate);

        LocalDate currentWeek = startDate.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        LocalDate lastWeek = endDate.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));

        int weeksProcessed = 0;
        while (!currentWeek.isAfter(lastWeek)) {
            calculateAndSaveWeeklyProgress(userId, currentWeek);
            currentWeek = currentWeek.plusWeeks(1);
            weeksProcessed++;
        }

        System.out.println("✅ Recalculated " + weeksProcessed + " weeks");
    }

    /**
     * Convert WeeklyProgress entity to response DTO
     */
    private WeeklyProgressResponse convertToResponse(WeeklyProgress progress) {
        WeeklyProgressResponse response = new WeeklyProgressResponse();
        response.setId(progress.getId());
        response.setUserId(progress.getUserId());
        response.setWeekStartDate(progress.getWeekStartDate());
        response.setWeekEndDate(progress.getWeekEndDate());
        response.setTotalSteps(progress.getTotalSteps());
        response.setTotalDistanceM(progress.getTotalDistanceM());
        response.setTotalCalories(progress.getTotalCalories());
        response.setDailyAverageSteps(progress.getDailyAverageSteps());
        response.setGoalDaysCount(progress.getGoalDaysCount());
        response.setBestDaySteps(progress.getBestDaySteps());
        response.setBestDayDate(progress.getBestDayDate());
        response.setCreatedAt(progress.getCreatedAt() != null ? progress.getCreatedAt().toString() : null);
        response.setUpdatedAt(progress.getUpdatedAt() != null ? progress.getUpdatedAt().toString() : null);
        
        // Add daily breakdown
        response.setDailyBreakdown(getDailyBreakdown(progress.getUserId(), progress.getWeekStartDate(), progress.getWeekEndDate()));
        
        return response;
    }

    /**
     * Get daily breakdown for a week
     */
    private List<WeeklyProgressResponse.DailyBreakdown> getDailyBreakdown(Long userId, LocalDate weekStart, LocalDate weekEnd) {
        List<WeeklyProgressResponse.DailyBreakdown> breakdown = new ArrayList<>();
        String[] dayNames = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"};
        
        // Get all daily data for the week
        List<Map<String, Object>> dailyData = stepsRepository.findStepHistoryByDateRange(userId, weekStart, weekEnd);
        
        // Create a map for quick lookup by date
        Map<LocalDate, Map<String, Object>> dataByDate = new HashMap<>();
        for (Map<String, Object> data : dailyData) {
            LocalDate date = (LocalDate) data.get("date");
            dataByDate.put(date, data);
        }
        
        // Create breakdown for each day of the week
        for (int i = 0; i < 7; i++) {
            LocalDate date = weekStart.plusDays(i);
            Map<String, Object> dayData = dataByDate.get(date);
            
            int steps = 0;
            double distanceM = 0.0;
            double calories = 0.0;
            
            if (dayData != null) {
                steps = ((Number) dayData.getOrDefault("totalSteps", 0)).intValue();
                distanceM = ((Number) dayData.getOrDefault("totalDistanceM", 0.0)).doubleValue();
                calories = ((Number) dayData.getOrDefault("totalCaloriesBurned", 0.0)).doubleValue();
            }
            
            breakdown.add(new WeeklyProgressResponse.DailyBreakdown(
                i + 1, // dayOfWeek: 1=Monday, 7=Sunday
                dayNames[i],
                date,
                steps,
                distanceM,
                calories
            ));
        }
        
        return breakdown;
    }

    /**
     * Delete weekly progress for a specific week
     */
    @Transactional
    public void deleteWeekProgress(Long userId, LocalDate weekStartDate) {
        weeklyProgressRepository.deleteByUserIdAndWeekStartDate(userId, weekStartDate);
        System.out.println("🗑️ Deleted weekly progress for user " + userId + ", week: " + weekStartDate);
    }
}
