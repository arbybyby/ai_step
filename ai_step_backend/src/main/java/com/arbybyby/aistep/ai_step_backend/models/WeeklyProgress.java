package com.arbybyby.aistep.ai_step_backend.models;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.Instant;

/**
 * WeeklyProgress entity - stores weekly step progress for users
 * Represents aggregated step data for a 7-day period
 */
@Entity
@Table(name = "weekly_progress", indexes = {
    @Index(name = "idx_user_week_start", columnList = "user_id, week_start_date"),
    @Index(name = "idx_week_start", columnList = "week_start_date")
})
public class WeeklyProgress {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "user_id", nullable = false)
    private Long userId;
    
    @Column(name = "week_start_date", nullable = false)
    private LocalDate weekStartDate; // Monday of the week
    
    @Column(name = "week_end_date", nullable = false)
    private LocalDate weekEndDate; // Sunday of the week
    
    @Column(name = "total_steps", nullable = false)
    private Integer totalSteps;
    
    @Column(name = "total_distance_m")
    private Double totalDistanceM;
    
    @Column(name = "total_calories")
    private Double totalCalories;
    
    @Column(name = "daily_average_steps")
    private Integer dailyAverageSteps;
    
    @Column(name = "goal_days_count") // Number of days goal was achieved
    private Integer goalDaysCount;
    
    @Column(name = "best_day_steps")
    private Integer bestDaySteps;
    
    @Column(name = "best_day_date")
    private LocalDate bestDayDate;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
    
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    // Constructors
    public WeeklyProgress() {
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    public WeeklyProgress(Long userId, LocalDate weekStartDate, LocalDate weekEndDate) {
        this.userId = userId;
        this.weekStartDate = weekStartDate;
        this.weekEndDate = weekEndDate;
        this.totalSteps = 0;
        this.totalDistanceM = 0.0;
        this.totalCalories = 0.0;
        this.dailyAverageSteps = 0;
        this.goalDaysCount = 0;
        this.bestDaySteps = 0;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

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

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = Instant.now();
    }

    @Override
    public String toString() {
        return "WeeklyProgress{" +
                "id=" + id +
                ", userId=" + userId +
                ", weekStartDate=" + weekStartDate +
                ", weekEndDate=" + weekEndDate +
                ", totalSteps=" + totalSteps +
                ", dailyAverageSteps=" + dailyAverageSteps +
                ", goalDaysCount=" + goalDaysCount +
                '}';
    }
}
