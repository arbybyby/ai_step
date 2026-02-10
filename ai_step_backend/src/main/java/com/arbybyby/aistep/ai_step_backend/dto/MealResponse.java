package com.arbybyby.aistep.ai_step_backend.dto;

public class MealResponse {
    private String message;
    private boolean success;

    // Constructors
    public MealResponse() {}

    public MealResponse(String message, boolean success) {
        this.message = message;
        this.success = success;
    }

    // Getters and setters
    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }
}
