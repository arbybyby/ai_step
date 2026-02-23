package com.arbybyby.aistep.ai_step_backend.dto;

import com.arbybyby.aistep.ai_step_backend.models.ActivityLevel;
import com.arbybyby.aistep.ai_step_backend.models.FitnessGoal;
import com.arbybyby.aistep.ai_step_backend.models.Gender;
import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDateTime;

public class UserRequest {
    @NotNull(message = "ID is required")
    private Integer id;
    
    @NotBlank(message = "Email is required")
    @Email(message = "Email should be valid")
    private String email;
    
    @NotBlank(message = "First name is required")
    private String firstName;
    
    @NotBlank(message = "Last name is required")
    private String lastName;
    
    @NotNull(message = "Age is required")
    private Integer age;
    
    @JsonAlias("heightCm")
    @NotNull(message = "Height is required")
    private Double height;
    
    @JsonAlias("weightKg")
    @NotNull(message = "Weight is required")
    private Double weight;
    
    @NotNull(message = "Gender is required")
    private Gender gender;
    
    @NotNull(message = "Activity level is required")
    private ActivityLevel activityLevel;
    
    @JsonAlias("fitnessGoal")
    @NotNull(message = "Goal is required")
    private FitnessGoal goal;
    
    @NotNull(message = "Verification status is required")
    private Boolean isVerified;
    
    @NotNull(message = "Created at is required")
    private LocalDateTime createdAt;
    
    @NotNull(message = "Calorie goal is required")
    private Double calorieGoal;
    
    @NotNull(message = "Protein goal is required")
    private Double proteinGoal;
    
    @NotNull(message = "Water goal is required")
    private Double waterGoal;
    
    @NotNull(message = "Steps goal is required")
    private Integer stepsGoal;

    // Default constructor
    public UserRequest() {
    }

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public Integer getAge() {
        return age;
    }

    public void setAge(Integer age) {
        this.age = age;
    }

    public Double getHeight() {
        return height;
    }

    public void setHeight(Double height) {
        this.height = height;
    }

    public Double getWeight() {
        return weight;
    }

    public void setWeight(Double weight) {
        this.weight = weight;
    }

    public Gender getGender() {
        return gender;
    }

    public void setGender(Gender gender) {
        this.gender = gender;
    }

    public ActivityLevel getActivityLevel() {
        return activityLevel;
    }

    public void setActivityLevel(ActivityLevel activityLevel) {
        this.activityLevel = activityLevel;
    }

    public FitnessGoal getGoal() {
        return goal;
    }

    public void setGoal(FitnessGoal goal) {
        this.goal = goal;
    }

    public Boolean getIsVerified() {
        return isVerified;
    }

    public void setIsVerified(Boolean isVerified) {
        this.isVerified = isVerified;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public Double getCalorieGoal() {
        return calorieGoal;
    }

    public void setCalorieGoal(Double calorieGoal) {
        this.calorieGoal = calorieGoal;
    }

    public Double getProteinGoal() {
        return proteinGoal;
    }

    public void setProteinGoal(Double proteinGoal) {
        this.proteinGoal = proteinGoal;
    }

    public Double getWaterGoal() {
        return waterGoal;
    }

    public void setWaterGoal(Double waterGoal) {
        this.waterGoal = waterGoal;
    }

    public Integer getStepsGoal() {
        return stepsGoal;
    }

    public void setStepsGoal(Integer stepsGoal) {
        this.stepsGoal = stepsGoal;
    }
}
