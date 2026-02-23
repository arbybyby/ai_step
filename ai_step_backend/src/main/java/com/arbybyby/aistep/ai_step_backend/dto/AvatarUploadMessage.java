package com.arbybyby.aistep.ai_step_backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public class AvatarUploadMessage {

    @JsonProperty("userId")
    private Integer userId;
    
    @JsonProperty("avatarPath")
    private String avatarPath;

    public AvatarUploadMessage() {
    }

    public AvatarUploadMessage(Integer userId, String avatarPath) {
        this.userId = userId;
        this.avatarPath = avatarPath;
    }

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    public String getAvatarPath() {
        return avatarPath;
    }

    public void setAvatarPath(String avatarPath) {
        this.avatarPath = avatarPath;
    }
}
