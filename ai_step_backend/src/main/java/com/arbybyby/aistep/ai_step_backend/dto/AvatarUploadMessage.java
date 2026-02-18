package com.arbybyby.aistep.ai_step_backend.dto;

public class AvatarUploadMessage {

    private Integer userId;
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
