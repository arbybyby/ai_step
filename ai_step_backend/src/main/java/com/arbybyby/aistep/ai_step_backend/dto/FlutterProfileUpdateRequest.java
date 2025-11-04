package com.arbybyby.aistep.ai_step_backend.dto;

import jakarta.validation.constraints.*;

public class FlutterProfileUpdateRequest {
    
    @Email(message = "Please provide a valid email address")
    private String email;
    
    @Size(min = 1, max = 50, message = "First name must be between 1 and 50 characters")
    private String firstName;
    
    @Size(min = 1, max = 50, message = "Last name must be between 1 and 50 characters")
    private String lastName;
    
    @DecimalMin(value = "50.0", message = "Height must be at least 50 cm")
    @DecimalMax(value = "300.0", message = "Height must be at most 300 cm")
    @Digits(integer = 3, fraction = 2, message = "Height should have at most 3 digits before decimal and 2 after")
    private Double heightCm;
    
    @DecimalMin(value = "20.0", message = "Weight must be at least 20 kg")  // Более реалистичный минимум
    @DecimalMax(value = "500.0", message = "Weight must be at most 500 kg")
    @Digits(integer = 3, fraction = 2, message = "Weight should have at most 3 digits before decimal and 2 after")
    private Double weightKg;
    
    @Pattern(regexp = "^(male|female|other)$", 
             message = "Gender must be one of: male, female, other")
    private String gender;
    
    @Pattern(regexp = "^(sedentary|lightly_active|moderately_active|very_active|extra_active)$", 
             message = "Activity level must be one of: sedentary, lightly_active, moderately_active, very_active, extra_active")
    private String activityLevel;
    
    @Pattern(regexp = "^(lose|maintain|gain)$", 
             message = "Goal must be one of: lose, maintain, gain")
    private String goal;
    
    @Pattern(regexp = "^\\d{4}-\\d{2}-\\d{2}$", 
             message = "Birth date must be in YYYY-MM-DD format (e.g., 1990-05-15)")
    private String birthDate;
    
    @Min(value = 13, message = "Age must be at least 13 years")
    @Max(value = 120, message = "Age must be at most 120 years")
    private Integer age;
    
    @Size(max = 10, message = "Locale must be at most 10 characters")
    private String locale;
    
    @Size(max = 50, message = "Timezone must be at most 50 characters")
    private String timezone;
    
    @Pattern(regexp = "^(metric|imperial)$", 
             message = "Units preference must be either 'metric' or 'imperial'")
    private String unitsPreference;

    // Constructors
    public FlutterProfileUpdateRequest() {}

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
    
    // Дополнительные методы валидации
    public boolean hasValidHeight() {
        return heightCm != null && heightCm >= 50.0 && heightCm <= 300.0;
    }
    
    public boolean hasValidWeight() {
        return weightKg != null && weightKg >= 20.0 && weightKg <= 500.0;
    }
    
    public boolean hasValidAge() {
        return age != null && age >= 13 && age <= 120;
    }
}