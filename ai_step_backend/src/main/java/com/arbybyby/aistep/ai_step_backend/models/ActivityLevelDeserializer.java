package com.arbybyby.aistep.ai_step_backend.models;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonToken;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;

import java.io.IOException;

public class ActivityLevelDeserializer extends JsonDeserializer<ActivityLevel> {
    @Override
    public ActivityLevel deserialize(JsonParser p, DeserializationContext ctxt) throws IOException {
        int value;
        if (p.currentToken() == JsonToken.VALUE_STRING) {
            String text = p.getText().trim();
            try {
                value = Integer.parseInt(text);
            } catch (NumberFormatException e) {
                try {
                    return ActivityLevel.valueOf(text.toUpperCase());
                } catch (IllegalArgumentException ex) {
                    return ActivityLevel.SEDENTARY;
                }
            }
        } else {
            value = p.getIntValue();
        }
        return ActivityLevel.fromValue(value);
    }
}
