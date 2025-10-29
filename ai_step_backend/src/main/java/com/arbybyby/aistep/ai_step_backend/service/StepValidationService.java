package com.arbybyby.aistep.ai_step_backend.service;

import com.arbybyby.aistep.ai_step_backend.dto.StepDataRequest;
import com.arbybyby.aistep.ai_step_backend.models.DailyStepTotals;
import com.arbybyby.aistep.ai_step_backend.models.StepData;
import com.arbybyby.aistep.ai_step_backend.repositories.InMemoryStepDataRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.ArrayList;

@Service
public class StepValidationService {

    @Autowired
    private InMemoryStepDataRepository stepDataRepository;

    // Константы для фильтрации
    private static final double MIN_STEP_MAGNITUDE = 1.5;  // Минимальная величина ускорения для шага
    private static final double MAX_STEP_MAGNITUDE = 25.0; // Максимальная величина ускорения для шага
    private static final double MIN_STEP_FREQUENCY = 0.5;  // Минимальная частота шагов (шагов в секунду)
    private static final double MAX_STEP_FREQUENCY = 4.0;  // Максимальная частота шагов (шагов в секунду)
    private static final long MIN_TIME_BETWEEN_STEPS_MS = 200; // Минимальное время между шагами (мс)
    private static final double GRAVITY = 9.81; // Ускорение свободного падения
    private static final double STATIC_THRESHOLD = 0.5; // Порог для определения статичного состояния

    /**
     * Обрабатывает входящие данные шагов и определяет их валидность
     */
    public StepData processStepData(Long userId, StepDataRequest request) {
        StepData stepData = new StepData(
            userId,
            request.getStepCount(),
            request.getAccelerometerData() != null ? request.getAccelerometerData().getX() : null,
            request.getAccelerometerData() != null ? request.getAccelerometerData().getY() : null,
            request.getAccelerometerData() != null ? request.getAccelerometerData().getZ() : null,
            request.getTimestamp() != null ? request.getTimestamp() : Instant.now()
        );

        stepData.setDeviceOrientation(request.getDeviceOrientation());
        stepData.setActivityType(request.getActivityType());

        // Вычисляем confidence score и определяем валидность
        double confidenceScore = calculateConfidenceScore(stepData, userId);
        stepData.setConfidenceScore(confidenceScore);
        stepData.setIsValidStep(confidenceScore > 0.5);

        return stepDataRepository.save(stepData);
    }

    /**
     * Вычисляет коэффициент уверенности в том, что зарегистрированный шаг является реальным
     */
    private double calculateConfidenceScore(StepData stepData, Long userId) {
        double score = 1.0;

        // 1. Проверка magnitude акселерометра
        score *= validateAccelerometerMagnitude(stepData);

        // 2. Проверка на статичное состояние (телефон лежит на столе)
        score *= validateStaticState(stepData);

        // 3. Проверка частоты шагов
        score *= validateStepFrequency(stepData, userId);

        // 4. Проверка ориентации устройства
        score *= validateDeviceOrientation(stepData);

        // 5. Проверка типа активности
        score *= validateActivityType(stepData);

        return Math.max(0.0, Math.min(1.0, score));
    }

    /**
     * Проверяет magnitude акселерометра
     */
    private double validateAccelerometerMagnitude(StepData stepData) {
        if (stepData.getMagnitude() == null) {
            return 0.3; // Низкая уверенность при отсутствии данных акселерометра
        }

        double magnitude = stepData.getMagnitude();
        
        // Если magnitude слишком мала (телефон неподвижен) или слишком велика (тряска)
        if (magnitude < MIN_STEP_MAGNITUDE) {
            return 0.1; // Очень низкая уверенность - возможно телефон неподвижен
        }
        
        if (magnitude > MAX_STEP_MAGNITUDE) {
            return 0.2; // Низкая уверенность - слишком сильные колебания
        }

        // Оптимальный диапазон для ходьбы
        if (magnitude >= 2.0 && magnitude <= 15.0) {
            return 1.0;
        }

        return 0.7; // Средняя уверенность
    }

    /**
     * Проверяет, находится ли устройство в статичном состоянии
     */
    private double validateStaticState(StepData stepData) {
        if (stepData.getAccelerometerX() == null || 
            stepData.getAccelerometerY() == null || 
            stepData.getAccelerometerZ() == null) {
            return 0.5;
        }

        // Вычисляем отклонение от гравитации
        double totalAcceleration = stepData.getMagnitude();
        double gravitationalDeviation = Math.abs(totalAcceleration - GRAVITY);

        // Если устройство почти неподвижно (близко к гравитации)
        if (gravitationalDeviation < STATIC_THRESHOLD) {
            return 0.1; // Очень низкая уверенность - устройство статично
        }

        // Проверяем вариацию по осям
        double maxAxis = Math.max(Math.abs(stepData.getAccelerometerX()), 
                         Math.max(Math.abs(stepData.getAccelerometerY()), 
                                 Math.abs(stepData.getAccelerometerZ())));
        
        if (maxAxis < 2.0) {
            return 0.2; // Низкая активность
        }

        return 1.0; // Хорошая активность
    }

    /**
     * Проверяет частоту шагов
     */
    private double validateStepFrequency(StepData stepData, Long userId) {
        // Получаем последние несколько записей для анализа частоты
        Instant fiveMinutesAgo = stepData.getTimestamp().minus(5, ChronoUnit.MINUTES);
        List<StepData> recentSteps = stepDataRepository.findByUserIdAndTimestampBetween(
            userId, fiveMinutesAgo, stepData.getTimestamp()
        );

        if (recentSteps.size() < 2) {
            return 0.8; // Недостаточно данных для анализа
        }

        // Вычисляем среднее время между шагами
        long totalTimeDiff = 0;
        for (int i = 0; i < recentSteps.size() - 1; i++) {
            totalTimeDiff += ChronoUnit.MILLIS.between(
                recentSteps.get(i + 1).getTimestamp(),
                recentSteps.get(i).getTimestamp()
            );
        }

        double avgTimeBetweenSteps = (double) totalTimeDiff / (recentSteps.size() - 1);
        
        // Если время между шагами слишком маленькое
        if (avgTimeBetweenSteps < MIN_TIME_BETWEEN_STEPS_MS) {
            return 0.2; // Слишком частые "шаги" - возможно ложные срабатывания
        }

        // Вычисляем частоту (шагов в секунду)
        double frequency = 1000.0 / avgTimeBetweenSteps;
        
        if (frequency < MIN_STEP_FREQUENCY || frequency > MAX_STEP_FREQUENCY) {
            return 0.3; // Нереалистичная частота
        }

        return 1.0; // Реалистичная частота
    }

    /**
     * Проверяет ориентацию устройства
     */
    private double validateDeviceOrientation(StepData stepData) {
        String orientation = stepData.getDeviceOrientation();
        
        if (orientation == null) {
            return 0.7; // Средняя уверенность при отсутствии данных
        }

        // Если устройство лежит плашмя, снижаем уверенность
        if ("flat".equalsIgnoreCase(orientation) || "face_down".equalsIgnoreCase(orientation)) {
            return 0.2;
        }

        // Вертикальные ориентации более вероятны для ходьбы
        if ("portrait".equalsIgnoreCase(orientation) || "upright".equalsIgnoreCase(orientation)) {
            return 1.0;
        }

        return 0.8; // Другие ориентации
    }

    /**
     * Проверяет тип активности
     */
    private double validateActivityType(StepData stepData) {
        String activityType = stepData.getActivityType();
        
        if (activityType == null) {
            return 0.7; // Средняя уверенность при отсутствии данных
        }

        switch (activityType.toLowerCase()) {
            case "walking":
            case "running":
            case "jogging":
                return 1.0;
            case "still":
            case "stationary":
                return 0.1; // Очень низкая уверенность для статичного состояния
            case "vehicle":
            case "in_vehicle":
                return 0.2; // Низкая уверенность в транспорте
            default:
                return 0.6; // Неизвестная активность
        }
    }

    /**
     * Получает дневную статистику шагов для пользователя
     */
    public List<DailyStepTotals> getDailyStepTotals(Long userId, int days) {
        Instant endTime = Instant.now();
        Instant startTime = endTime.minus(days, ChronoUnit.DAYS);

        List<Object[]> results = stepDataRepository.getDailyStepTotalsByUserId(userId, startTime, endTime);
        List<DailyStepTotals> dailyTotals = new ArrayList<>();

        for (Object[] result : results) {
            // Convert SQL Date to java.util.Date for DailyStepTotals
            java.sql.Date sqlDate = (java.sql.Date) result[0];
            java.util.Date day = new java.util.Date(sqlDate.getTime());
            Integer totalSteps = ((Number) result[1]).intValue();
            Double totalDistanceM = result[2] != null ? ((Number) result[2]).doubleValue() : 0.0;
            Integer totalCalories = ((Number) result[3]).intValue();
            Instant lastEntryAt = (Instant) result[4];

            dailyTotals.add(new DailyStepTotals(day, totalSteps, totalDistanceM, totalCalories, lastEntryAt));
        }

        return dailyTotals;
    }

    /**
     * Получает количество валидных шагов за день
     */
    public Integer getValidStepsForToday(Long userId) {
        LocalDate today = LocalDate.now();
        Instant startOfDay = today.atStartOfDay(ZoneId.systemDefault()).toInstant();
        Instant endOfDay = today.plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant();

        return stepDataRepository.countValidStepsByUserIdAndTimestampBetween(userId, startOfDay, endOfDay);
    }

    /**
     * Получает все данные шагов за период
     */
    public List<StepData> getStepDataForPeriod(Long userId, Instant startTime, Instant endTime) {
        return stepDataRepository.findByUserIdAndTimestampBetween(userId, startTime, endTime);
    }

    /**
     * Получает только валидные шаги за период
     */
    public List<StepData> getValidStepDataForPeriod(Long userId, Instant startTime, Instant endTime) {
        return stepDataRepository.findValidStepsByUserIdAndTimestampBetween(userId, startTime, endTime);
    }
}