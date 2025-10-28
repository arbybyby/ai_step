package com.arbybyby.aistep.ai_step_backend.controller;

import com.arbybyby.aistep.ai_step_backend.dto.StepDataRequest;
import com.arbybyby.aistep.ai_step_backend.models.DailyStepTotals;
import com.arbybyby.aistep.ai_step_backend.models.StepData;
import com.arbybyby.aistep.ai_step_backend.security.UserPrincipal;
import com.arbybyby.aistep.ai_step_backend.service.StepValidationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/steps")
@PreAuthorize("hasRole('USER') or hasRole('MODERATOR') or hasRole('ADMIN')")
public class StepsController {

    @Autowired
    private StepValidationService stepValidationService;

    /**
     * Отправка данных о шагах с акселерометра
     */
    @PostMapping("/submit")
    public ResponseEntity<?> submitStepData(@RequestBody StepDataRequest request, Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            StepData processedStepData = stepValidationService.processStepData(userId, request);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("stepData", Map.of(
                "id", processedStepData.getId(),
                "stepCount", processedStepData.getStepCount(),
                "isValidStep", processedStepData.getIsValidStep(),
                "confidenceScore", processedStepData.getConfidenceScore(),
                "timestamp", processedStepData.getTimestamp()
            ));

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to process step data: " + e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    /**
     * Получение текущего количества шагов за сегодня
     */
    @GetMapping("/today")
    public ResponseEntity<?> getTodaySteps(Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            Integer validStepsToday = stepValidationService.getValidStepsForToday(userId);

            Map<String, Object> response = new HashMap<>();
            response.put("date", LocalDate.now().toString());
            response.put("totalSteps", validStepsToday);
            response.put("distance", validStepsToday * 0.78 / 1000.0); // km
            response.put("calories", validStepsToday * 0.04);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to get today's steps: " + e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    /**
     * Получение статистики шагов за определенный период
     */
    @GetMapping("/daily")
    public ResponseEntity<?> getDailyStepStats(
            @RequestParam(defaultValue = "7") int days,
            Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            List<DailyStepTotals> dailyTotals = stepValidationService.getDailyStepTotals(userId, days);

            Map<String, Object> response = new HashMap<>();
            response.put("period", days + " days");
            response.put("dailyStats", dailyTotals);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to get daily stats: " + e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    /**
     * Получение детальных данных шагов за период
     */
    @GetMapping("/detailed")
    public ResponseEntity<?> getDetailedStepData(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(defaultValue = "true") boolean validOnly,
            Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            Instant startTime = startDate.atStartOfDay(ZoneId.systemDefault()).toInstant();
            Instant endTime = endDate.plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant();

            List<StepData> stepData;
            if (validOnly) {
                stepData = stepValidationService.getValidStepDataForPeriod(userId, startTime, endTime);
            } else {
                stepData = stepValidationService.getStepDataForPeriod(userId, startTime, endTime);
            }

            Map<String, Object> response = new HashMap<>();
            response.put("startDate", startDate.toString());
            response.put("endDate", endDate.toString());
            response.put("validOnly", validOnly);
            response.put("totalRecords", stepData.size());
            response.put("stepData", stepData);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to get detailed step data: " + e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    /**
     * Получение статистики валидации (для отладки)
     */
    @GetMapping("/validation-stats")
    public ResponseEntity<?> getValidationStats(Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            // Получаем данные за последние 24 часа
            Instant last24Hours = Instant.now().minusSeconds(24 * 60 * 60);
            Instant now = Instant.now();

            List<StepData> allSteps = stepValidationService.getStepDataForPeriod(userId, last24Hours, now);
            List<StepData> validSteps = stepValidationService.getValidStepDataForPeriod(userId, last24Hours, now);

            int totalSteps = allSteps.size();
            int validStepsCount = validSteps.size();
            int invalidStepsCount = totalSteps - validStepsCount;
            
            double validationRate = totalSteps > 0 ? (double) validStepsCount / totalSteps : 0.0;

            Map<String, Object> response = new HashMap<>();
            response.put("period", "last 24 hours");
            response.put("totalSteps", totalSteps);
            response.put("validSteps", validStepsCount);
            response.put("invalidSteps", invalidStepsCount);
            response.put("validationRate", Math.round(validationRate * 100.0) + "%");
            
            // Статистика confidence scores
            if (!allSteps.isEmpty()) {
                double avgConfidence = allSteps.stream()
                    .mapToDouble(step -> step.getConfidenceScore() != null ? step.getConfidenceScore() : 0.0)
                    .average()
                    .orElse(0.0);
                response.put("averageConfidence", Math.round(avgConfidence * 100.0) / 100.0);
            }

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to get validation stats: " + e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    /**
     * Массовая отправка данных о шагах (для пакетной обработки)
     */
    @PostMapping("/batch")
    public ResponseEntity<?> submitBatchStepData(@RequestBody List<StepDataRequest> requests, Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            int processedCount = 0;
            int validCount = 0;

            for (StepDataRequest request : requests) {
                StepData processedStepData = stepValidationService.processStepData(userId, request);
                processedCount++;
                if (processedStepData.getIsValidStep()) {
                    validCount++;
                }
            }

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("processedCount", processedCount);
            response.put("validCount", validCount);
            response.put("invalidCount", processedCount - validCount);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to process batch step data: " + e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }
}