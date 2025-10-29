package com.arbybyby.aistep.ai_step_backend.controller;

import com.arbybyby.aistep.ai_step_backend.dto.StepSubmissionRequest;
import com.arbybyby.aistep.ai_step_backend.models.Steps;
import com.arbybyby.aistep.ai_step_backend.security.UserPrincipal;
import com.arbybyby.aistep.ai_step_backend.service.StepsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.RequestMethod;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@CrossOrigin(
    origins = {"http://localhost:*", "http://192.168.1.82:*", "https://*"}, 
    allowedHeaders = {"*"}, 
    methods = {RequestMethod.GET, RequestMethod.POST, RequestMethod.PUT, RequestMethod.DELETE, RequestMethod.OPTIONS},
    allowCredentials = "true",
    maxAge = 3600
)
@RestController
@RequestMapping("/api")
public class StepsController {
    @Autowired
    private StepsService stepsService;

    /**
     * Handle preflight OPTIONS requests for CORS
     */
    @RequestMapping(value = "/steps/**", method = RequestMethod.OPTIONS)
    public ResponseEntity<?> handlePreflight() {
        return ResponseEntity.ok().build();
    }

    /**
     * Health check endpoint for Flutter app connectivity
     */
    @GetMapping("/steps/health")
    public ResponseEntity<?> healthCheck(Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();
            
            Map<String, Object> health = new HashMap<>();
            health.put("status", "ok");
            health.put("user_id", userId);
            health.put("timestamp", Instant.now().toString());
            health.put("service", "steps");
            
            return ResponseEntity.ok(health);
        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Health check failed");
            error.put("timestamp", Instant.now().toString());
            
            return ResponseEntity.internalServerError().body(error);
        }
    }

    /**
     * Отправка данных о шагах (совместимость с Node.js API)
     * Corresponds to: app.post('/steps', auth, async (req, res) => {...})
     */
    @PostMapping("/steps")
    public ResponseEntity<?> submitSteps(@RequestBody StepSubmissionRequest request, Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();
            
            System.out.println("Received steps submission request from user: " + userId);
            System.out.println("Request data: " + request.getStepCount() + " steps at " + request.getRecordedAt());

            // Validate step_count manually to match Node.js validation exactly
            Integer stepCount = request.getStepCount();
            if (stepCount == null || stepCount < 0 || !isInteger(stepCount)) {
                System.out.println("Invalid step count: " + stepCount);
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "step_count must be a non-negative integer"));
            }

            // Validate recorded_at
            Instant recordedAt = request.getRecordedAt();
            if (recordedAt == null) {
                System.out.println("Missing recorded_at field");
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "recorded_at is required"));
            }

            // Validate optional numeric fields (distance_m, calories_burned)
            try {
                validateOptionalNumber(request.getDistanceM());
                validateOptionalNumber(request.getCaloriesBurned());
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "distance_m and calories_burned must be numeric values"));
            }

            // Save step data
            Steps savedSteps = stepsService.saveStepData(userId, request);

            // Compute daily totals for the recorded date
            Map<String, Object> totals = stepsService.computeDailyStepTotals(userId, savedSteps.getRecordedDate());

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Steps stored");
            response.put("step_id", savedSteps.getId());
            response.put("recorded_at", savedSteps.getRecordedAt().toString());
            response.put("totals", totals);
            
            System.out.println("Successfully saved steps with ID: " + savedSteps.getId());

            return ResponseEntity.status(201).body(response);
        } catch (IllegalArgumentException e) {
            System.err.println("Validation error for steps submission: " + e.getMessage());
            return ResponseEntity.badRequest()
                .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            System.err.println("Steps insert error: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                .body(Map.of("error", "Server error inserting steps", "details", e.getMessage()));
        }
    }

    /**
     * Helper method to validate integer values exactly like Node.js
     */
    private boolean isInteger(Integer value) {
        return value != null && value.equals(value.intValue());
    }

    /**
     * Helper method to validate optional numeric fields exactly like Node.js normalizeOptionalNumber
     */
    private void validateOptionalNumber(Double value) {
        if (value != null && !Double.isFinite(value)) {
            throw new IllegalArgumentException("invalid_number");
        }
    }

    /**
     * Get daily step totals for a specific date
     * Corresponds to: app.get('/steps/daily', auth, async (req, res) => {...})
     */
    @GetMapping("/steps/daily")
    public ResponseEntity<?> getDailySteps(@RequestParam(required = false) String date, Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();
            
            System.out.println("Fetching daily steps for user: " + userId + ", date: " + date);

            Map<String, Object> totals = stepsService.getDailyStepTotals(userId, date);
            
            // Check if has data (matching Node.js logic)
            // Handle both Integer and Long types from database SUM operations
            Object totalStepsObj = totals.get("total_steps");
            Integer totalSteps = totalStepsObj != null ? ((Number) totalStepsObj).intValue() : null;
            Double totalDistanceM = (Double) totals.get("total_distance_m");
            Double totalCalories = (Double) totals.get("total_calories");
            String lastEntryAt = (String) totals.get("last_entry_at");
            
            boolean hasData = (totalSteps != null && totalSteps > 0) ||
                            (totalDistanceM != null && totalDistanceM > 0) ||
                            (totalCalories != null && totalCalories > 0) ||
                            (lastEntryAt != null);

            Map<String, Object> response = new HashMap<>();
            response.put("day", totals.get("day"));
            response.put("data", hasData ? totals : null);

            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            System.err.println("Validation error for daily steps: " + e.getMessage());
            if ("INVALID_DATE".equals(e.getMessage())) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "Invalid date. Expected format YYYY-MM-DD."));
            }
            return ResponseEntity.badRequest()
                .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            System.err.println("Daily steps fetch error: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                .body(Map.of("error", "Server error fetching daily steps", "details", e.getMessage()));
        }
    }

    /**
     * Get step history for a date range
     * Corresponds to: app.get('/steps/history', auth, async (req, res) => {...})
     */
    @GetMapping("/steps/history")
    public ResponseEntity<?> getStepHistory(@RequestParam(required = false) String from, 
                                          @RequestParam(required = false) String to, 
                                          Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();
            
            System.out.println("Fetching step history for user: " + userId + ", from: " + from + ", to: " + to);

            Map<String, Object> history = stepsService.fetchStepHistory(userId, from, to);
            
            return ResponseEntity.ok(history);
        } catch (IllegalArgumentException e) {
            System.err.println("Validation error for step history: " + e.getMessage());
            String errorCode = e.getMessage();
            if ("INVALID_FROM_DATE".equals(errorCode) || "INVALID_TO_DATE".equals(errorCode)) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "Invalid date. Expected format YYYY-MM-DD."));
            } else if ("INVALID_RANGE".equals(errorCode)) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "from date must be before or equal to to date."));
            }
            return ResponseEntity.badRequest()
                .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            System.err.println("Steps history fetch error: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                .body(Map.of("error", "Server error fetching steps history", "details", e.getMessage()));
        }
    }

}