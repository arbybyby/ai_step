package com.arbybyby.aistep.ai_step_backend.models;

import java.time.Instant;
import java.time.LocalDate;

public class Steps {
    private Long id;
    private Long userId;
    private String deviceId;
    private Integer stepCount;
    private Double distanceM;
    private Double caloriesBurned;
    private Instant recordedAt;
    private LocalDate recordedDate;

    // Constructors
    public Steps() {}

    public Steps(Long userId, String deviceId, Integer stepCount, 
                 Double distanceM, Double caloriesBurned, Instant recordedAt, LocalDate recordedDate) {
        this.userId = userId;
        this.deviceId = deviceId;
        this.stepCount = stepCount;
        this.distanceM = distanceM;
        this.caloriesBurned = caloriesBurned;
        this.recordedAt = recordedAt;
        this.recordedDate = recordedDate;
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

    public String getDeviceId() { 
        return deviceId; 
    }

    public void setDeviceId(String deviceId) { 
        this.deviceId = deviceId; 
    }

    public Integer getStepCount() { 
        return stepCount; 
    }

    public void setStepCount(Integer stepCount) { 
        this.stepCount = stepCount; 
    }

    public Double getDistanceM() { 
        return distanceM; 
    }

    public void setDistanceM(Double distanceM) { 
        this.distanceM = distanceM; 
    }

    public Double getCaloriesBurned() { 
        return caloriesBurned; 
    }

    public void setCaloriesBurned(Double caloriesBurned) { 
        this.caloriesBurned = caloriesBurned; 
    }

    public Instant getRecordedAt() { 
        return recordedAt; 
    }

    public void setRecordedAt(Instant recordedAt) { 
        this.recordedAt = recordedAt; 
    }

    public LocalDate getRecordedDate() { 
        return recordedDate; 
    }

    public void setRecordedDate(LocalDate recordedDate) { 
        this.recordedDate = recordedDate; 
    }
}