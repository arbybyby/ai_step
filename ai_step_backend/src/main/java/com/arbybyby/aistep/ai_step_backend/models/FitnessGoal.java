package com.arbybyby.aistep.ai_step_backend.models;

import com.fasterxml.jackson.annotation.JsonValue;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;

@JsonDeserialize(using = FitnessGoalDeserializer.class)
public enum FitnessGoal {
    LOSE_WEIGHT(0),
    MAINTAIN_WEIGHT(1),
    GAIN_MUSCLE(2);

    private final int value;

    FitnessGoal(int value) {
        this.value = value;
    }

    @JsonValue
    public int getValue() {
        return value;
    }

    public static FitnessGoal fromValue(int value) {
        for (FitnessGoal goal : FitnessGoal.values()) {
            if (goal.value == value) {
                return goal;
            }
        }
        return LOSE_WEIGHT;
    }
}
