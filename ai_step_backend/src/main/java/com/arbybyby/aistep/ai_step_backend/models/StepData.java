package com.arbybyby.aistep.ai_step_backend.models;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "step_data")
public class StepData {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "step_count", nullable = false)
    private Integer stepCount;

    @Column(name = "accelerometer_x")
    private Double accelerometerX;

    @Column(name = "accelerometer_y")
    private Double accelerometerY;

    @Column(name = "accelerometer_z")
    private Double accelerometerZ;

    @Column(name = "magnitude")
    private Double magnitude;

    @Column(name = "confidence_score")
    private Double confidenceScore;

    @Column(name = "is_valid_step")
    private Boolean isValidStep = true;

    @Column(name = "timestamp", nullable = false)
    private Instant timestamp;

    @Column(name = "device_orientation")
    private String deviceOrientation;

    @Column(name = "activity_type")
    private String activityType;

    // Constructors
    public StepData() {}

    public StepData(Long userId, Integer stepCount, Double accelerometerX, 
                   Double accelerometerY, Double accelerometerZ, Instant timestamp) {
        this.userId = userId;
        this.stepCount = stepCount;
        this.accelerometerX = accelerometerX;
        this.accelerometerY = accelerometerY;
        this.accelerometerZ = accelerometerZ;
        this.timestamp = timestamp;
        this.magnitude = calculateMagnitude(accelerometerX, accelerometerY, accelerometerZ);
    }

    // Helper method to calculate magnitude
    private Double calculateMagnitude(Double x, Double y, Double z) {
        if (x == null || y == null || z == null) return null;
        return Math.sqrt(x * x + y * y + z * z);
    }

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Integer getStepCount() { return stepCount; }
    public void setStepCount(Integer stepCount) { this.stepCount = stepCount; }

    public Double getAccelerometerX() { return accelerometerX; }
    public void setAccelerometerX(Double accelerometerX) { 
        this.accelerometerX = accelerometerX;
        updateMagnitude();
    }

    public Double getAccelerometerY() { return accelerometerY; }
    public void setAccelerometerY(Double accelerometerY) { 
        this.accelerometerY = accelerometerY;
        updateMagnitude();
    }

    public Double getAccelerometerZ() { return accelerometerZ; }
    public void setAccelerometerZ(Double accelerometerZ) { 
        this.accelerometerZ = accelerometerZ;
        updateMagnitude();
    }

    public Double getMagnitude() { return magnitude; }
    public void setMagnitude(Double magnitude) { this.magnitude = magnitude; }

    public Double getConfidenceScore() { return confidenceScore; }
    public void setConfidenceScore(Double confidenceScore) { this.confidenceScore = confidenceScore; }

    public Boolean getIsValidStep() { return isValidStep; }
    public void setIsValidStep(Boolean isValidStep) { this.isValidStep = isValidStep; }

    public Instant getTimestamp() { return timestamp; }
    public void setTimestamp(Instant timestamp) { this.timestamp = timestamp; }

    public String getDeviceOrientation() { return deviceOrientation; }
    public void setDeviceOrientation(String deviceOrientation) { this.deviceOrientation = deviceOrientation; }

    public String getActivityType() { return activityType; }
    public void setActivityType(String activityType) { this.activityType = activityType; }

    private void updateMagnitude() {
        this.magnitude = calculateMagnitude(accelerometerX, accelerometerY, accelerometerZ);
    }
}