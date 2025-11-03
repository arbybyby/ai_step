package com.arbybyby.aistep.ai_step_backend.dto;

import jakarta.validation.constraints.NotBlank;

public class GoogleSignInRequest {
    @NotBlank(message = "ID token is required")
    private String idToken;

    public GoogleSignInRequest() {}

    public GoogleSignInRequest(String idToken) {
        this.idToken = idToken;
    }

    public String getIdToken() {
        return idToken;
    }

    public void setIdToken(String idToken) {
        this.idToken = idToken;
    }
}