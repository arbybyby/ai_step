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
import java.util.List;
import java.util.Map;

@Service
public class StepsService {

    @Autowired
    private StepsRepository stepsRepository;

    public Steps saveStepData(Long userId, StepSubmissionRequest request) {
        // Get validated data from request (validation is done in controller)
        Integer stepCount = request.getStepCount();
        Instant recordedAt = request.getRecordedAt();
        
        // Convert to LocalDate for the recorded_date field
        LocalDate recordedDate = recordedAt.atZone(ZoneId.systemDefault()).toLocalDate();

        // Normalize optional numeric fields (matching Node.js normalizeOptionalNumber logic)
        Double distanceM = normalizeOptionalNumber(request.getDistanceM());
        Double caloriesBurned = normalizeOptionalNumber(request.getCaloriesBurned());

        System.out.println("Saving step data:");
        System.out.println("  User ID: " + userId);
        System.out.println("  Step count: " + stepCount);
        System.out.println("  Recorded at: " + recordedAt);
        System.out.println("  Recorded date: " + recordedDate);
        System.out.println("  Distance: " + distanceM);
        System.out.println("  Calories: " + caloriesBurned);

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

        Steps saved = stepsRepository.save(steps);
        System.out.println("✅ Saved step data with ID: " + saved.getId());
        System.out.println("   Verified saved data:");
        System.out.println("   - Step count: " + saved.getStepCount());
        System.out.println("   - Distance M: " + saved.getDistanceM());
        System.out.println("   - Calories: " + saved.getCaloriesBurned());
        
        return saved;
    }

    public Map<String, Object> computeDailyStepTotals(Long userId, LocalDate date) {
        Object[] totals = stepsRepository.findDailyTotals(userId, date);
        
        Map<String, Object> result = new HashMap<>();
        
        // Проверяем, что массив содержит ожидаемое количество элементов
        if (totals != null && totals.length >= 3) {
            result.put("total_steps", totals[0] != null ? totals[0] : 0);
            result.put("total_distance_m", totals[1] != null ? totals[1] : 0.0);
            result.put("total_calories", totals[2] != null ? totals[2] : 0.0);
        } else {
            // Значения по умолчанию, если нет данных
            result.put("total_steps", 0);
            result.put("total_distance_m", 0.0);
            result.put("total_calories", 0.0);
        }
        
        // Используем "day" вместо "date" для совместимости с контроллером
        result.put("day", date.toString());
        
        return result;
    }

    /**
     * Get daily step totals for a specific date with validation
     * Matches Node.js computeDailyStepTotals function
     */
    public Map<String, Object> getDailyStepTotals(Long userId, String dateStr) {
        LocalDate date;
        try {
            if (dateStr == null || dateStr.trim().isEmpty()) {
                date = LocalDate.now();
            } else {
                date = LocalDate.parse(dateStr);
            }
        } catch (Exception e) {
            throw new IllegalArgumentException("INVALID_DATE");
        }

        System.out.println("═══════════════════════════════════════");
        System.out.println("📊 Getting daily totals for user " + userId + " on date " + date);
        System.out.println("Date string input: '" + dateStr + "'");
        System.out.println("Parsed LocalDate: " + date);
        
        Object[] totals = stepsRepository.findDailyTotals(userId, date);
        
        System.out.println("📈 Database SUM query returned: " + (totals != null ? java.util.Arrays.toString(totals) : "null"));
        
        // Get last entry time for the day
        List<Steps> daySteps = stepsRepository.findByUserIdAndRecordedDateOrderByRecordedAtDesc(userId, date);
        Instant lastEntryAt = daySteps.isEmpty() ? null : daySteps.get(0).getRecordedAt();
        
        System.out.println("📋 Found " + daySteps.size() + " step entries for this day");
        
        Map<String, Object> result = computeDailyStepTotals(userId, date);
        
        if (!daySteps.isEmpty()) {
            System.out.println("📋 Actual data from database:");
            
            for (int i = 0; i < Math.min(daySteps.size(), 5); i++) {
                Steps step = daySteps.get(i);
                System.out.println("  Entry " + (i+1) + ": ID=" + step.getId() + 
                    ", steps=" + step.getStepCount() + 
                    ", distance=" + step.getDistanceM() + 
                    ", calories=" + step.getCaloriesBurned() + 
                    ", recorded_date=" + step.getRecordedDate() +
                    ", recorded_at=" + step.getRecordedAt());
            }
            
            // Check if all dates match
            boolean allDatesMatch = daySteps.stream()
                .allMatch(s -> s.getRecordedDate().equals(date));
            System.out.println("✓ All recorded_date match query date: " + allDatesMatch);
            
            // Calculate manual sum for comparison and use it
            int manualSum = daySteps.stream()
                .mapToInt(s -> s.getStepCount() != null ? s.getStepCount() : 0)
                .sum();
            System.out.println("🧮 Manual sum of steps: " + manualSum);
            result.put("total_steps", manualSum);
        }
        
        result.put("last_entry_at", lastEntryAt != null ? lastEntryAt.toString() : null);
        
        System.out.println("📤 Returning result: " + result);
        System.out.println("═══════════════════════════════════════");
        
        return result;
    }

    /**
     * Fetch step history for a date range
     * Matches Node.js fetchStepHistory function
     */
    public Map<String, Object> fetchStepHistory(Long userId, String fromStr, String toStr) {
        LocalDate fromDate;
        LocalDate toDate;
        
        try {
            if (fromStr == null || fromStr.trim().isEmpty()) {
                fromDate = LocalDate.now().minusDays(7);
            } else {
                fromDate = LocalDate.parse(fromStr);
            }
        } catch (Exception e) {
            throw new IllegalArgumentException("INVALID_FROM_DATE");
        }
        
        try {
            if (toStr == null || toStr.trim().isEmpty()) {
                toDate = LocalDate.now();
            } else {
                toDate = LocalDate.parse(toStr);
            }
        } catch (Exception e) {
            throw new IllegalArgumentException("INVALID_TO_DATE");
        }
        
        if (fromDate.isAfter(toDate)) {
            throw new IllegalArgumentException("INVALID_RANGE");
        }
        
        // Get history data (this would need a new repository method)
        List<Map<String, Object>> historyData = stepsRepository.findStepHistoryByDateRange(userId, fromDate, toDate);
        
        Map<String, Object> result = new HashMap<>();
        result.put("from", fromDate.toString());
        result.put("to", toDate.toString());
        result.put("history", historyData);
        
        return result;
    }

    /**
     * Normalizes optional number fields exactly like Node.js normalizeOptionalNumber function
     * Returns null for undefined/null/'', throws error for invalid numbers, returns parsed value otherwise
     */
    private Double normalizeOptionalNumber(Double value) {
        // if (value === undefined || value === null || value === '') return null;
        if (value == null) {
            return null;
        }
        
        // const parsed = Number(value);
        // if (!Number.isFinite(parsed)) { throw new Error('invalid_number'); }
        if (!Double.isFinite(value)) {
            throw new IllegalArgumentException("invalid_number");
        }
        
        return value;
    }
}