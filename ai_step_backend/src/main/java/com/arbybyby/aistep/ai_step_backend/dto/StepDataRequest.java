package com.arbybyby.aistep.ai_step_backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;

public class StepDataRequest {
    
    @JsonProperty("step_count")
    private Integer stepCount;
    
    @JsonProperty("accelerometer_data")
    private AccelerometerData accelerometerData;
    
    @JsonProperty("timestamp")
    private Instant timestamp;
    
    @JsonProperty("device_orientation")
    private String deviceOrientation;
    
    @JsonProperty("activity_type")
    private String activityType;

    // Nested class for accelerometer data
    public static class AccelerometerData {
        @JsonProperty("x")
        private Double x;
        
        @JsonProperty("y")
        private Double y;
        
        @JsonProperty("z")
        private Double z;

        public AccelerometerData() {}

        public AccelerometerData(Double x, Double y, Double z) {
            this.x = x;
            this.y = y;
            this.z = z;
        }

        // Getters and setters
        public Double getX() { return x; }
        public void setX(Double x) { this.x = x; }

        public Double getY() { return y; }
        public void setY(Double y) { this.y = y; }

        public Double getZ() { return z; }
        public void setZ(Double z) { this.z = z; }
    }

    // Constructors
    public StepDataRequest() {}

    public StepDataRequest(Integer stepCount, AccelerometerData accelerometerData, Instant timestamp) {
        this.stepCount = stepCount;
        this.accelerometerData = accelerometerData;
        this.timestamp = timestamp;
    }

    // Getters and setters
    public Integer getStepCount() { return stepCount; }
    public void setStepCount(Integer stepCount) { this.stepCount = stepCount; }

    public AccelerometerData getAccelerometerData() { return accelerometerData; }
    public void setAccelerometerData(AccelerometerData accelerometerData) { 
        this.accelerometerData = accelerometerData; 
    }

    public Instant getTimestamp() { return timestamp; }
    public void setTimestamp(Instant timestamp) { this.timestamp = timestamp; }

    public String getDeviceOrientation() { return deviceOrientation; }
    public void setDeviceOrientation(String deviceOrientation) { this.deviceOrientation = deviceOrientation; }

    public String getActivityType() { return activityType; }
    public void setActivityType(String activityType) { this.activityType = activityType; }
}