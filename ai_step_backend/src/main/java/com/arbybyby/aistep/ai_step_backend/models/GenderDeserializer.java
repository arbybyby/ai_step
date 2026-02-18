package com.arbybyby.aistep.ai_step_backend.models;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonToken;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;

import java.io.IOException;

public class GenderDeserializer extends JsonDeserializer<Gender> {
    @Override
    public Gender deserialize(JsonParser p, DeserializationContext ctxt) throws IOException {
        int value;
        if (p.currentToken() == JsonToken.VALUE_STRING) {
            String text = p.getText().trim();
            try {
                value = Integer.parseInt(text);
            } catch (NumberFormatException e) {
                // Try matching by name (e.g. "MALE", "male")
                try {
                    return Gender.valueOf(text.toUpperCase());
                } catch (IllegalArgumentException ex) {
                    return Gender.NONE;
                }
            }
        } else {
            value = p.getIntValue();
        }
        return Gender.fromValue(value);
    }
}
