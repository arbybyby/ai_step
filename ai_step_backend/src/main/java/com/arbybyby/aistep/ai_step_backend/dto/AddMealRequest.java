package com.arbybyby.aistep.ai_step_backend.dto;

import com.arbybyby.aistep.ai_step_backend.models.MealType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public class AddMealRequest {
    // UserID is extracted from JWT token when security is enabled, or from request body otherwise
    private Integer userID;
    
    @NotNull(message = "MealID is required")
    private Integer mealID;
    
    @NotNull(message = "MealType is required")
    private MealType mealType;
    
    @NotNull(message = "Grammes is required")
    @Positive(message = "Grammes must be positive")
    private Float grammes;
    
    @NotNull(message = "Timestamp is required")
    private String timestamp;

    // Constructors
    public AddMealRequest() {}

    public AddMealRequest(Integer userID, Integer mealID, MealType mealType, 
                         Float grammes, String timestamp) {
        this.userID = userID;
        this.mealID = mealID;
        this.mealType = mealType;
        this.grammes = grammes;
        this.timestamp = timestamp;
    }

    // Getters and setters
    public Integer getUserID() {
        return userID;
    }

    public void setUserID(Integer userID) {
        this.userID = userID;
    }

    public Integer getMealID() {
        return mealID;
    }

    public void setMealID(Integer mealID) {
        this.mealID = mealID;
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

    public String getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(String timestamp) {
        this.timestamp = timestamp;
    }
}
