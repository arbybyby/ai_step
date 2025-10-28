package com.arbybyby.aistep.ai_step_backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public class StepSubmissionRequest {
    
    @JsonProperty("step_count")
    @NotNull(message = "step_count is required")
    @Min(value = 0, message = "step_count must be a non-negative integer")
    private Integer stepCount;
    
    @JsonProperty("recorded_at")
    @NotNull(message = "recorded_at is required")
    private Instant recordedAt;
    
    @JsonProperty("distance_m")
    private Double distanceM;
    
    @JsonProperty("calories_burned")
    private Double caloriesBurned;
    
    @JsonProperty("device_id")
    private String deviceId;

    // Constructors
    public StepSubmissionRequest() {}

    public StepSubmissionRequest(Integer stepCount, Instant recordedAt) {
        this.stepCount = stepCount;
        this.recordedAt = recordedAt;
    }

    // Getters and setters
    public Integer getStepCount() { 
        return stepCount; 
    }
    
    public void setStepCount(Integer stepCount) { 
        this.stepCount = stepCount; 
    }

    public Instant getRecordedAt() { 
        return recordedAt; 
    }
    
    public void setRecordedAt(Instant recordedAt) { 
        this.recordedAt = recordedAt; 
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

    public String getDeviceId() { 
        return deviceId; 
    }
    
    public void setDeviceId(String deviceId) { 
        this.deviceId = deviceId; 
    }
}