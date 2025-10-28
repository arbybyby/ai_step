package com.arbybyby.aistep.ai_step_backend.service;

import com.arbybyby.aistep.ai_step_backend.dto.StepSubmissionRequest;
import com.arbybyby.aistep.ai_step_backend.models.Steps;
import com.arbybyby.aistep.ai_step_backend.repositories.StepsRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.Map;

@Service
public class StepsService {

    @Autowired
    private StepsRepository stepsRepository;

    public Steps saveStepData(Long userId, StepSubmissionRequest request) {
        // Validate step count
        Integer stepCount = request.getStepCount();
        if (stepCount == null || stepCount < 0) {
            throw new IllegalArgumentException("step_count must be a non-negative integer");
        }

        // Validate recorded_at
        Instant recordedAt = request.getRecordedAt();
        if (recordedAt == null) {
            throw new IllegalArgumentException("recorded_at is required");
        }

        // Convert to LocalDate for the recorded_date field
        LocalDate recordedDate = recordedAt.atZone(ZoneId.systemDefault()).toLocalDate();

        // Validate and normalize optional numeric fields
        Double distanceM = normalizeOptionalNumber(request.getDistanceM(), "distance_m");
        Double caloriesBurned = normalizeOptionalNumber(request.getCaloriesBurned(), "calories_burned");

        // Create and save the step data
        Steps steps = new Steps(
            userId,
            request.getDeviceId(),
            stepCount,
            distanceM,
            caloriesBurned,
            recordedAt,
            recordedDate
        );

        return stepsRepository.save(steps);
    }

    public Map<String, Object> computeDailyStepTotals(Long userId, LocalDate date) {
        Object[] totals = stepsRepository.findDailyTotals(userId, date);
        
        Map<String, Object> result = new HashMap<>();
        result.put("total_steps", totals[0]);
        result.put("total_distance_m", totals[1]);
        result.put("total_calories_burned", totals[2]);
        result.put("date", date.toString());
        
        return result;
    }

    private Double normalizeOptionalNumber(Double value, String fieldName) {
        if (value == null) {
            return null;
        }
        
        if (!Double.isFinite(value)) {
            throw new IllegalArgumentException(fieldName + " must be a numeric value");
        }
        
        return value;
    }
}