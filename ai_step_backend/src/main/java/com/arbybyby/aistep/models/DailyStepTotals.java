package com.arbybyby.aistep.models;

import java.time.Instant;
import java.util.Date;

public class DailyStepTotals {
    private Date day;
    private Integer totalSteps;
    private Double totalDistanceM;
    private Integer totalCalories;
    private Instant lastEntryAt;

    public DailyStepTotals(Date day, Integer totalSteps, Double totalDistanceM, Integer totalCalories, Instant lastEntryAt) {
        this.day = day;
        this.totalSteps = totalSteps;
        this.totalDistanceM = totalDistanceM;
        this.totalCalories = totalCalories;
        this.lastEntryAt = lastEntryAt;
    }

    public Date getDay() {
        return day;
    }

    public Integer getTotalSteps() {
        return totalSteps;
    }

    public Double getTotalDistanceM() {
        return totalDistanceM;
    }

    public Integer getTotalCalories() {
        return totalCalories;
    }

    public Instant getLastEntryAt() {
        return lastEntryAt;
    }
}
