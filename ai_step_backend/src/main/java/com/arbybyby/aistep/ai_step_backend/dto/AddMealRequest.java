package com.arbybyby.aistep.ai_step_backend.dto;

import com.arbybyby.aistep.ai_step_backend.models.MealType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public class AddMealRequest {
    // UserID is now extracted from JWT token, not from request body
    private Integer userID;
    
    @NotBlank(message = "MealName is required")
    private String mealName;
    
    @NotNull(message = "MealType is required")
    private MealType mealType;
    
    @NotNull(message = "Grammes is required")
    @Positive(message = "Grammes must be positive")
    private Float grammes;
    
    @NotNull(message = "Calories is required")
    @Positive(message = "Calories must be positive")
    private Float calories;
    
    @NotNull(message = "Protein is required")
    private Float protein;
    
    @NotNull(message = "Carbs is required")
    private Float carbs;
    
    @NotNull(message = "Fat is required")
    private Float fat;

    // Constructors
    public AddMealRequest() {}

    public AddMealRequest(Integer userID, String mealName, MealType mealType, 
                         Float grammes, Float calories, Float protein, Float carbs, Float fat) {
        this.userID = userID;
        this.mealName = mealName;
        this.mealType = mealType;
        this.grammes = grammes;
        this.calories = calories;
        this.protein = protein;
        this.carbs = carbs;
        this.fat = fat;
    }

    // Getters and setters
    public Integer getUserID() {
        return userID;
    }

    public void setUserID(Integer userID) {
        this.userID = userID;
    }

    public String getMealName() {
        return mealName;
    }

    public void setMealName(String mealName) {
        this.mealName = mealName;
    }

    public MealType getMealType() {
        return mealType;
    }

    public void setMealType(MealType mealType) {
        this.mealType = mealType;
    }

    public Float getGrammes() {
        return grammes;
    }

    public void setGrammes(Float grammes) {
        this.grammes = grammes;
    }

    public Float getCalories() {
        return calories;
    }

    public void setCalories(Float calories) {
        this.calories = calories;
    }

    public Float getProtein() {
        return protein;
    }

    public void setProtein(Float protein) {
        this.protein = protein;
    }

    public Float getCarbs() {
        return carbs;
    }

    public void setCarbs(Float carbs) {
        this.carbs = carbs;
    }

    public Float getFat() {
        return fat;
    }

    public void setFat(Float fat) {
        this.fat = fat;
    }
}
