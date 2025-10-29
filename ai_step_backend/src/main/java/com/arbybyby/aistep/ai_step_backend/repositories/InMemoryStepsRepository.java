package com.arbybyby.aistep.ai_step_backend.repositories;

import com.arbybyby.aistep.ai_step_backend.models.Steps;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;

@Repository
public class InMemoryStepsRepository {
    private final Map<Long, Steps> stepsData = new ConcurrentHashMap<>();
    private final AtomicLong idGenerator = new AtomicLong(1);

    public Steps save(Steps steps) {
        if (steps.getId() == null) {
            steps.setId(idGenerator.getAndIncrement());
        }
        stepsData.put(steps.getId(), steps);
        return steps;
    }

    public Optional<Steps> findById(Long id) {
        return Optional.ofNullable(stepsData.get(id));
    }

    public List<Steps> findAll() {
        return new ArrayList<>(stepsData.values());
    }

    public void deleteById(Long id) {
        stepsData.remove(id);
    }

    public void delete(Steps steps) {
        stepsData.remove(steps.getId());
    }

    public Object[] findDailyTotals(Long userId, LocalDate date) {
        List<Steps> daySteps = stepsData.values().stream()
                .filter(step -> Objects.equals(step.getUserId(), userId))
                .filter(step -> Objects.equals(step.getRecordedDate(), date))
                .collect(Collectors.toList());

        if (daySteps.isEmpty()) {
            return new Object[]{0L, 0.0, 0.0};
        }

        long totalSteps = daySteps.stream()
                .mapToLong(step -> step.getStepCount() != null ? step.getStepCount() : 0)
                .sum();

        double totalDistance = daySteps.stream()
                .mapToDouble(step -> step.getDistanceM() != null ? step.getDistanceM() : 0.0)
                .sum();

        double totalCalories = daySteps.stream()
                .mapToDouble(step -> step.getCaloriesBurned() != null ? step.getCaloriesBurned() : 0.0)
                .sum();

        return new Object[]{totalSteps, totalDistance, totalCalories};
    }

    public List<Steps> findByUserIdAndRecordedDateOrderByRecordedAtDesc(Long userId, LocalDate recordedDate) {
        return stepsData.values().stream()
                .filter(step -> Objects.equals(step.getUserId(), userId))
                .filter(step -> Objects.equals(step.getRecordedDate(), recordedDate))
                .sorted((s1, s2) -> s2.getRecordedAt().compareTo(s1.getRecordedAt()))
                .collect(Collectors.toList());
    }

    public List<Map<String, Object>> findStepHistoryByDateRange(Long userId, LocalDate fromDate, LocalDate toDate) {
        Map<LocalDate, List<Steps>> groupedByDate = stepsData.values().stream()
                .filter(step -> Objects.equals(step.getUserId(), userId))
                .filter(step -> {
                    LocalDate stepDate = step.getRecordedDate();
                    return stepDate != null && 
                           !stepDate.isBefore(fromDate) && 
                           !stepDate.isAfter(toDate);
                })
                .collect(Collectors.groupingBy(Steps::getRecordedDate));

        List<Map<String, Object>> result = new ArrayList<>();
        
        for (Map.Entry<LocalDate, List<Steps>> entry : groupedByDate.entrySet()) {
            LocalDate date = entry.getKey();
            List<Steps> steps = entry.getValue();
            
            long totalSteps = steps.stream()
                    .mapToLong(step -> step.getStepCount() != null ? step.getStepCount() : 0)
                    .sum();
            
            double totalDistanceM = steps.stream()
                    .mapToDouble(step -> step.getDistanceM() != null ? step.getDistanceM() : 0.0)
                    .sum();
            
            double totalCaloriesBurned = steps.stream()
                    .mapToDouble(step -> step.getCaloriesBurned() != null ? step.getCaloriesBurned() : 0.0)
                    .sum();
            
            Map<String, Object> dayResult = new HashMap<>();
            dayResult.put("date", date);
            dayResult.put("totalSteps", totalSteps);
            dayResult.put("totalDistanceM", totalDistanceM);
            dayResult.put("totalCaloriesBurned", totalCaloriesBurned);
            
            result.add(dayResult);
        }
        
        // Сортируем по дате по возрастанию
        result.sort((m1, m2) -> ((LocalDate) m1.get("date")).compareTo((LocalDate) m2.get("date")));
        
        return result;
    }

    public long count() {
        return stepsData.size();
    }

    public boolean existsById(Long id) {
        return stepsData.containsKey(id);
    }

    public void deleteAll() {
        stepsData.clear();
    }
}