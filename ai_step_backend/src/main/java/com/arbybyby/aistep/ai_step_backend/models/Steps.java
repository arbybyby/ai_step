package com.arbybyby.aistep.ai_step_backend.models;

import jakarta.persistence.*;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "steps")
public class Steps {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "device_id")
    private String deviceId;

    @Column(name = "step_count", nullable = false)
    private Integer stepCount;

    @Column(name = "distance_m")
    private Double distanceM;

    @Column(name = "calories_burned")
    private Double caloriesBurned;

    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;

    @Column(name = "recorded_date", nullable = false)
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