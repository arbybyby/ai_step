 package com.arbybyby.aistep.ai_step_backend.models;

import java.time.LocalDateTime;


public class User {
    private Integer id;
    private String email;
    private String firstName;
    private String lastName;
    private Integer age;
    private Double height;
    private Double weight;
    private Gender gender;
    private ActivityLevel activityLevel;
    private FitnessGoal goal;
    private Boolean isVerified;
    private LocalDateTime createdAt;
    private Double calorieGoal;
    private Double proteinGoal;
    private Double waterGoal;
    private Integer stepsGoal;

    // Default constructor
    public User() {
    }

    // Constructor with all fields
    public User(Integer id, String email, String firstName, String lastName, Integer age, 
                Double height, Double weight, Gender gender, ActivityLevel activityLevel, FitnessGoal goal,
                Boolean isVerified, LocalDateTime createdAt, Double calorieGoal, Double proteinGoal,
                Double waterGoal, Integer stepsGoal) {
        this.id = id;
        this.email = email;
        this.firstName = firstName;
        this.lastName = lastName;
        this.age = age;
        this.height = height;
        this.weight = weight;
        this.gender = gender;
        this.activityLevel = activityLevel;
        this.goal = goal;
        this.isVerified = isVerified;
        this.createdAt = createdAt;
        this.calorieGoal = calorieGoal;
        this.proteinGoal = proteinGoal;
        this.waterGoal = waterGoal;
        this.stepsGoal = stepsGoal;
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

    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", email='" + email + '\'' +
                ", firstName='" + firstName + '\'' +
                ", lastName='" + lastName + '\'' +
                ", age=" + age +
                ", height=" + height +
                ", weight=" + weight +
                ", gender=" + gender +
                ", activityLevel='" + activityLevel + '\'' +
                ", goal='" + goal + '\'' +
                ", isVerified=" + isVerified +
                ", createdAt=" + createdAt +
                ", calorieGoal=" + calorieGoal +
                ", proteinGoal=" + proteinGoal +
                ", waterGoal=" + waterGoal +
                ", stepsGoal=" + stepsGoal +
                '}';
    }
}
