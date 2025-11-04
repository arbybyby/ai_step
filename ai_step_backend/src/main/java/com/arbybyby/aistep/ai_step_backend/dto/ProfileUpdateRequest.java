package com.arbybyby.aistep.ai_step_backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;

public class ProfileUpdateRequest {
    @Email
    private String email;
    
    private String firstName;
    private String lastName;
    
    @DecimalMin(value = "50.0", message = "Height must be at least 50 cm")
    @DecimalMax(value = "300.0", message = "Height must be at most 300 cm")
    private Double heightCm;
    
    @DecimalMin(value = "30.0", message = "Weight must be at least 30 kg")
    @DecimalMax(value = "500.0", message = "Weight must be at most 500 kg")
    private Double weightKg;
    
    @Pattern(regexp = "^(male|female|other)$", message = "Gender must be male, female, or other")
    private String gender;
    
    @Pattern(regexp = "^(sedentary|lightly_active|moderately_active|very_active|extra_active)$", 
             message = "Activity level must be sedentary, lightly_active, moderately_active, very_active, or extra_active")
    private String activityLevel;
    
    @Pattern(regexp = "^(lose|maintain|gain)$", message = "Goal must be lose, maintain, or gain")
    private String goal;
    
    @Pattern(regexp = "^\\d{4}-\\d{2}-\\d{2}$", message = "Birth date must be in YYYY-MM-DD format")
    private String birthDate;
    
    @Min(value = 13, message = "Age must be at least 13")
    @Max(value = 120, message = "Age must be at most 120")
    private Integer age;
    
    private String locale;
    private String timezone;
    
    @Pattern(regexp = "^(metric|imperial)$", message = "Units preference must be metric or imperial")
    private String unitsPreference;

    // Constructors
    public ProfileUpdateRequest() {}

    // Getters and setters
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public Double getHeightCm() { return heightCm; }
    public void setHeightCm(Double heightCm) { this.heightCm = heightCm; }

    public Double getWeightKg() { return weightKg; }
    public void setWeightKg(Double weightKg) { this.weightKg = weightKg; }

    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }

    public String getActivityLevel() { return activityLevel; }
    public void setActivityLevel(String activityLevel) { this.activityLevel = activityLevel; }

    public String getGoal() { return goal; }
    public void setGoal(String goal) { this.goal = goal; }

    public String getBirthDate() { return birthDate; }
    public void setBirthDate(String birthDate) { this.birthDate = birthDate; }

    public Integer getAge() { return age; }
    public void setAge(Integer age) { this.age = age; }

    public String getLocale() { return locale; }
    public void setLocale(String locale) { this.locale = locale; }

    public String getTimezone() { return timezone; }
    public void setTimezone(String timezone) { this.timezone = timezone; }

    public String getUnitsPreference() { return unitsPreference; }
    public void setUnitsPreference(String unitsPreference) { this.unitsPreference = unitsPreference; }
}