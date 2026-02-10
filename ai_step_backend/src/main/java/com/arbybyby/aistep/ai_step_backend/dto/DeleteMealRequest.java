package com.arbybyby.aistep.ai_step_backend.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public class DeleteMealRequest {
    @NotNull(message = "Id is required")
    @Positive(message = "Id must be positive")
    private Integer id;
    
    // UserID is now extracted from JWT token, not from request body
    private Integer userID;

    // Constructors
    public DeleteMealRequest() {}

    public DeleteMealRequest(Integer id, Integer userID) {
        this.id = id;
        this.userID = userID;
    }

    // Getters and setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getUserID() {
        return userID;
    }

    public void setUserID(Integer userID) {
        this.userID = userID;
    }
}
