package com.arbybyby.aistep.ai_step_backend.utils;

import com.arbybyby.aistep.ai_step_backend.dto.FlutterProfileUpdateRequest;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.Period;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

@Component
public class ProfileValidationUtils {
    
    /**
     * Валидация данных профиля от Flutter с дополнительными проверками
     */
    public ValidationResult validateFlutterProfileData(FlutterProfileUpdateRequest request) {
        List<String> errors = new ArrayList<>();
        List<String> warnings = new ArrayList<>();
        
        // Проверка имен
        if (request.getFirstName() != null) {
            if (request.getFirstName().trim().isEmpty()) {
                errors.add("First name cannot be empty");
            } else if (request.getFirstName().length() > 50) {
                errors.add("First name is too long (max 50 characters)");
            } else if (!request.getFirstName().matches("^[a-zA-Zа-яА-Я\\s-']+$")) {
                errors.add("First name contains invalid characters");
            }
        }
        
        if (request.getLastName() != null) {
            if (request.getLastName().trim().isEmpty()) {
                errors.add("Last name cannot be empty");
            } else if (request.getLastName().length() > 50) {
                errors.add("Last name is too long (max 50 characters)");
            } else if (!request.getLastName().matches("^[a-zA-Zа-яА-Я\\s-']+$")) {
                errors.add("Last name contains invalid characters");
            }
        }
        
        // Проверка роста и веса для расчета ИМТ
        if (request.getHeightCm() != null && request.getWeightKg() != null) {
            if (request.getHeightCm() > 0 && request.getWeightKg() > 0) {
                double bmi = calculateBMI(request.getHeightCm(), request.getWeightKg());
                
                if (bmi < 16) {
                    warnings.add("Extremely low BMI detected. Please consult a healthcare provider.");
                } else if (bmi < 18.5) {
                    warnings.add("Low BMI detected. Consider consulting a healthcare provider.");
                } else if (bmi > 35) {
                    warnings.add("High BMI detected. Please consult a healthcare provider.");
                } else if (bmi > 30) {
                    warnings.add("Elevated BMI detected. Consider consulting a healthcare provider.");
                }
            }
        }
        
        // Проверка возраста и даты рождения
        if (request.getBirthDate() != null && request.getAge() != null) {
            try {
                LocalDate birthDate = LocalDate.parse(request.getBirthDate(), DateTimeFormatter.ofPattern("yyyy-MM-dd"));
                int calculatedAge = Period.between(birthDate, LocalDate.now()).getYears();
                
                if (Math.abs(calculatedAge - request.getAge()) > 1) {
                    warnings.add("Age and birth date don't match. Calculated age: " + calculatedAge);
                }
            } catch (DateTimeParseException e) {
                errors.add("Invalid birth date format. Use YYYY-MM-DD format.");
            }
        }
        
        // Проверка комбинации цели и уровня активности
        if (request.getGoal() != null && request.getActivityLevel() != null) {
            if ("lose".equals(request.getGoal()) && "sedentary".equals(request.getActivityLevel())) {
                warnings.add("Weight loss with sedentary lifestyle may be challenging. Consider increasing activity level.");
            } else if ("gain".equals(request.getGoal()) && "extra_active".equals(request.getActivityLevel())) {
                warnings.add("Weight gain with very high activity may require significantly increased caloric intake.");
            }
        }
        
        return new ValidationResult(errors.isEmpty(), errors, warnings);
    }
    
    /**
     * Расчет ИМТ
     */
    public double calculateBMI(double heightCm, double weightKg) {
        double heightM = heightCm / 100.0;
        return weightKg / (heightM * heightM);
    }
    
    /**
     * Получение категории ИМТ
     */
    public String getBMICategory(double bmi) {
        if (bmi < 16) {
            return "Severe underweight";
        } else if (bmi < 18.5) {
            return "Underweight";
        } else if (bmi < 25) {
            return "Normal weight";
        } else if (bmi < 30) {
            return "Overweight";
        } else if (bmi < 35) {
            return "Obese Class I";
        } else if (bmi < 40) {
            return "Obese Class II";
        } else {
            return "Obese Class III";
        }
    }
    
    /**
     * Класс для результата валидации
     */
    public static class ValidationResult {
        private final boolean valid;
        private final List<String> errors;
        private final List<String> warnings;
        
        public ValidationResult(boolean valid, List<String> errors, List<String> warnings) {
            this.valid = valid;
            this.errors = errors;
            this.warnings = warnings;
        }
        
        public boolean isValid() { return valid; }
        public List<String> getErrors() { return errors; }
        public List<String> getWarnings() { return warnings; }
        
        public boolean hasWarnings() { return !warnings.isEmpty(); }
        public boolean hasErrors() { return !errors.isEmpty(); }
    }
}