package com.arbybyby.aistep.ai_step_backend.models;

import com.fasterxml.jackson.annotation.JsonProperty;

public class Meal {
    @JsonProperty("Id")
    private int id;
    
    @JsonProperty("UserID")
    private int userID;
    
    @JsonProperty("MealID")
    private int mealID;
    
    @JsonProperty("MealType")
    private MealType mealType;
    
    @JsonProperty("Grammes")
    private float grammes;
    
    @JsonProperty("Timestamp")
    private String timestamp;

    // Constructors
    public Meal() {}

    public Meal(int id, int userID, int mealID, MealType mealType, 
                float grammes, String timestamp) {
        this.id = id;
        this.userID = userID;
        this.mealID = mealID;
        this.mealType = mealType;
        this.grammes = grammes;
        this.timestamp = timestamp;
    }

    // Getters and setters
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getUserID() {
        return userID;
    }

    public void setUserID(int userID) {
        this.userID = userID;
    }

    public int getMealID() {
        return mealID;
    }

    public void setMealID(int mealID) {
        this.mealID = mealID;
    }

    public MealType getMealType() {
        return mealType;
    }

    public void setMealType(MealType mealType) {
        this.mealType = mealType;
    }

    public float getGrammes() {
        return grammes;
    }

    public void setGrammes(float grammes) {
        this.grammes = grammes;
    }

    public String getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(String timestamp) {
        this.timestamp = timestamp;
    }
}
