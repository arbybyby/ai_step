package com.arbybyby.aistep.ai_step_backend.models;

import com.fasterxml.jackson.annotation.JsonValue;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;

@JsonDeserialize(using = ActivityLevelDeserializer.class)
public enum ActivityLevel {
    SEDENTARY(0),
    LIGHT(1),
    MODERATE(2),
    ACTIVE(3),
    VERY_ACTIVE(4);

    private final int value;

    ActivityLevel(int value) {
        this.value = value;
    }

    @JsonValue
    public int getValue() {
        return value;
    }

    public static ActivityLevel fromValue(int value) {
        for (ActivityLevel level : ActivityLevel.values()) {
            if (level.value == value) {
                return level;
            }
        }
        return SEDENTARY;
    }
}
