package com.arbybyby.aistep.ai_step_backend.repositories;

import com.arbybyby.aistep.ai_step_backend.models.StepData;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;

@Repository
public class InMemoryStepDataRepository {
    private final Map<Long, StepData> stepData = new ConcurrentHashMap<>();
    private final AtomicLong idGenerator = new AtomicLong(1);

    public StepData save(StepData data) {
        if (data.getId() == null) {
            data.setId(idGenerator.getAndIncrement());
        }
        stepData.put(data.getId(), data);
        return data;
    }

    public Optional<StepData> findById(Long id) {
        return Optional.ofNullable(stepData.get(id));
    }

    public List<StepData> findAll() {
        return new ArrayList<>(stepData.values());
    }

    public void deleteById(Long id) {
        stepData.remove(id);
    }

    public void delete(StepData data) {
        stepData.remove(data.getId());
    }

    public List<StepData> findByUserIdAndTimestampBetween(Long userId, Instant startTime, Instant endTime) {
        return stepData.values().stream()
                .filter(data -> Objects.equals(data.getUserId(), userId))
                .filter(data -> !data.getTimestamp().isBefore(startTime) && !data.getTimestamp().isAfter(endTime))
                .sorted((d1, d2) -> d2.getTimestamp().compareTo(d1.getTimestamp()))
                .collect(Collectors.toList());
    }

    public List<StepData> findValidStepsByUserIdAndTimestampBetween(Long userId, Instant startTime, Instant endTime) {
        return stepData.values().stream()
                .filter(data -> Objects.equals(data.getUserId(), userId))
                .filter(data -> data.getIsValidStep() != null && data.getIsValidStep())
                .filter(data -> !data.getTimestamp().isBefore(startTime) && !data.getTimestamp().isAfter(endTime))
                .sorted((d1, d2) -> d2.getTimestamp().compareTo(d1.getTimestamp()))
                .collect(Collectors.toList());
    }

    public Integer countValidStepsByUserIdAndTimestampBetween(Long userId, Instant startTime, Instant endTime) {
        return (int) stepData.values().stream()
                .filter(data -> Objects.equals(data.getUserId(), userId))
                .filter(data -> data.getIsValidStep() != null && data.getIsValidStep())
                .filter(data -> !data.getTimestamp().isBefore(startTime) && !data.getTimestamp().isAfter(endTime))
                .count();
    }

    public List<Object[]> getDailyStepTotalsByUserId(Long userId, Instant startTime, Instant endTime) {
        // Group by date
        Map<LocalDate, List<StepData>> groupedByDate = stepData.values().stream()
                .filter(data -> Objects.equals(data.getUserId(), userId))
                .filter(data -> !data.getTimestamp().isBefore(startTime) && !data.getTimestamp().isAfter(endTime))
                .collect(Collectors.groupingBy(data -> 
                    data.getTimestamp().atZone(ZoneId.systemDefault()).toLocalDate()));

        List<Object[]> result = new ArrayList<>();
        
        for (Map.Entry<LocalDate, List<StepData>> entry : groupedByDate.entrySet()) {
            LocalDate day = entry.getKey();
            List<StepData> dayData = entry.getValue();
            
            long totalSteps = dayData.stream()
                    .filter(data -> data.getIsValidStep() != null && data.getIsValidStep())
                    .count();
            
            double totalDistanceM = dayData.stream()
                    .filter(data -> data.getIsValidStep() != null && data.getIsValidStep())
                    .mapToDouble(data -> data.getMagnitude() != null ? data.getMagnitude() * 0.78 / 1000.0 : 0.0)
                    .sum();
            
            double totalCalories = totalSteps * 0.04;
            
            Instant lastEntryAt = dayData.stream()
                    .map(StepData::getTimestamp)
                    .max(Instant::compareTo)
                    .orElse(null);
            
            result.add(new Object[]{day, totalSteps, totalDistanceM, totalCalories, lastEntryAt});
        }
        
        // Sort by date descending
        result.sort((a, b) -> ((LocalDate) b[0]).compareTo((LocalDate) a[0]));
        
        return result;
    }

    public long count() {
        return stepData.size();
    }

    public boolean existsById(Long id) {
        return stepData.containsKey(id);
    }

    public void deleteAll() {
        stepData.clear();
    }
}