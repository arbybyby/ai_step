package com.arbybyby.aistep.ai_step_backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDate;
import java.util.List;

/**
 * Response DTO for Weekly Progress data
 */
public class WeeklyProgressResponse {
    private Long id;
    @JsonProperty("user_id")
    private Long userId;
    @JsonProperty("week_start_date")
    private LocalDate weekStartDate;
    @JsonProperty("week_end_date")
    private LocalDate weekEndDate;
    @JsonProperty("total_steps")
    private Integer totalSteps;
    @JsonProperty("total_distance_m")
    private Double totalDistanceM;
    @JsonProperty("total_distance_km")
    private Double totalDistanceKm;
    @JsonProperty("total_calories")
    private Double totalCalories;
    @JsonProperty("daily_average_steps")
    private Integer dailyAverageSteps;
    @JsonProperty("goal_days_count")
    private Integer goalDaysCount;
    @JsonProperty("best_day_steps")
    private Integer bestDaySteps;
    @JsonProperty("best_day_date")
    private LocalDate bestDayDate;
    @JsonProperty("created_at")
    private String createdAt;
    @JsonProperty("updated_at")
    private String updatedAt;
    @JsonProperty("daily_breakdown")
    private List<DailyBreakdown> dailyBreakdown;

    // Inner class for daily breakdown
    public static class DailyBreakdown {
        @JsonProperty("day_of_week")
        private Integer dayOfWeek; // 1=Monday, 7=Sunday
        @JsonProperty("day_name")
        private String dayName;
        private LocalDate date;
        private Integer steps;
        @JsonProperty("distance_m")
        private Double distanceM;
        private Double calories;

        public DailyBreakdown() {}

        public DailyBreakdown(Integer dayOfWeek, String dayName, LocalDate date, Integer steps, Double distanceM, Double calories) {
            this.dayOfWeek = dayOfWeek;
            this.dayName = dayName;
            this.date = date;
            this.steps = steps;
            this.distanceM = distanceM;
            this.calories = calories;
        }

        // Getters and setters
        public Integer getDayOfWeek() { return dayOfWeek; }
        public void setDayOfWeek(Integer dayOfWeek) { this.dayOfWeek = dayOfWeek; }
        
        public String getDayName() { return dayName; }
        public void setDayName(String dayName) { this.dayName = dayName; }
        
        public LocalDate getDate() { return date; }
        public void setDate(LocalDate date) { this.date = date; }
        
        public Integer getSteps() { return steps; }
        public void setSteps(Integer steps) { this.steps = steps; }
        
        public Double getDistanceM() { return distanceM; }
        public void setDistanceM(Double distanceM) { this.distanceM = distanceM; }
        
        public Double getCalories() { return calories; }
        public void setCalories(Double calories) { this.calories = calories; }
    }

    // Constructors
    public WeeklyProgressResponse() {}

    // Getters and setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public LocalDate getWeekStartDate() {
        return weekStartDate;
    }

    public void setWeekStartDate(LocalDate weekStartDate) {
        this.weekStartDate = weekStartDate;
    }

    public LocalDate getWeekEndDate() {
        return weekEndDate;
    }

    public void setWeekEndDate(LocalDate weekEndDate) {
        this.weekEndDate = weekEndDate;
    }

    public Integer getTotalSteps() {
        return totalSteps;
    }

    public void setTotalSteps(Integer totalSteps) {
        this.totalSteps = totalSteps;
    }

    public Double getTotalDistanceM() {
        return totalDistanceM;
    }

    public void setTotalDistanceM(Double totalDistanceM) {
        this.totalDistanceM = totalDistanceM;
        // Auto-calculate km when meters are set
        if (totalDistanceM != null) {
            this.totalDistanceKm = totalDistanceM / 1000.0;
        }
    }

    public Double getTotalDistanceKm() {
        return totalDistanceKm;
    }

    public void setTotalDistanceKm(Double totalDistanceKm) {
        this.totalDistanceKm = totalDistanceKm;
    }

    public Double getTotalCalories() {
        return totalCalories;
    }

    public void setTotalCalories(Double totalCalories) {
        this.totalCalories = totalCalories;
    }

    public Integer getDailyAverageSteps() {
        return dailyAverageSteps;
    }

    public void setDailyAverageSteps(Integer dailyAverageSteps) {
        this.dailyAverageSteps = dailyAverageSteps;
    }

    public Integer getGoalDaysCount() {
        return goalDaysCount;
    }

    public void setGoalDaysCount(Integer goalDaysCount) {
        this.goalDaysCount = goalDaysCount;
    }

    public Integer getBestDaySteps() {
        return bestDaySteps;
    }

    public void setBestDaySteps(Integer bestDaySteps) {
        this.bestDaySteps = bestDaySteps;
    }

    public LocalDate getBestDayDate() {
        return bestDayDate;
    }

    public void setBestDayDate(LocalDate bestDayDate) {
        this.bestDayDate = bestDayDate;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    public String getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(String updatedAt) {
        this.updatedAt = updatedAt;
    }

    public List<DailyBreakdown> getDailyBreakdown() {
        return dailyBreakdown;
    }

    public void setDailyBreakdown(List<DailyBreakdown> dailyBreakdown) {
        this.dailyBreakdown = dailyBreakdown;
    }
}

