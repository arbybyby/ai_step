package com.arbybyby.aistep.ai_step_backend.models;

import com.fasterxml.jackson.annotation.JsonProperty;

public class Meal {
    @JsonProperty("Id")
    private int id;
    
    @JsonProperty("UserID")
    private int userID;
    
    @JsonProperty("MealName")
    private String mealName;
    
    @JsonProperty("MealType")
    private MealType mealType;
    
    @JsonProperty("Grammes")
    private float grammes;
    
    @JsonProperty("Calories")
    private float calories;
    
    @JsonProperty("Protein")
    private float protein;
    
    @JsonProperty("Carbs")
    private float carbs;
    
    @JsonProperty("Fat")
    private float fat;

    // Constructors
    public Meal() {}

    public Meal(int id, int userID, String mealName, MealType mealType, 
                float grammes, float calories, float protein, float carbs, float fat) {
        this.id = id;
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

    public float getGrammes() {
        return grammes;
    }

    public void setGrammes(float grammes) {
        this.grammes = grammes;
    }

    public float getCalories() {
        return calories;
    }

    public void setCalories(float calories) {
        this.calories = calories;
    }

    public float getProtein() {
        return protein;
    }

    public void setProtein(float protein) {
        this.protein = protein;
    }

    public float getCarbs() {
        return carbs;
    }

    public void setCarbs(float carbs) {
        this.carbs = carbs;
    }

    public float getFat() {
        return fat;
    }

    public void setFat(float fat) {
        this.fat = fat;
    }
}
