package com.arbybyby.aistep.ai_step_backend.exception;

/**
 * Thrown when service-level input validation fails.
 */
public class ValidationException extends RuntimeException {

    public ValidationException(String message) {
        super(message);
    }

    public ValidationException(String message, Throwable cause) {
        super(message, cause);
    }
}
