package com.arbybyby.aistep.ai_step_backend.service;

import com.arbybyby.aistep.ai_step_backend.config.RabbitMQConfig;
import com.arbybyby.aistep.ai_step_backend.exception.ValidationException;
import com.arbybyby.aistep.ai_step_backend.models.Meal;
import com.arbybyby.aistep.ai_step_backend.models.MealType;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.amqp.rabbit.core.RabbitTemplate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MealQueueServiceTest {

    @Mock
    private RabbitTemplate rabbitTemplate;

    @InjectMocks
    private MealQueueService mealQueueService;

    // ===================== sendAddMealMessage =====================

    @Test
    void sendAddMealMessage_validMeal_sendsToQueue() {
        Meal meal = validAddMeal();

        mealQueueService.sendAddMealMessage(meal);

        ArgumentCaptor<Meal> captor = ArgumentCaptor.forClass(Meal.class);
        verify(rabbitTemplate).convertAndSend(
                eq(RabbitMQConfig.MEALS_EXCHANGE),
                eq(RabbitMQConfig.ADD_MEAL_ROUTING_KEY),
                captor.capture());
        assertThat(captor.getValue().getMealID()).isEqualTo(42);
    }

    @Test
    void sendAddMealMessage_nullMeal_throwsValidationException() {
        assertThatThrownBy(() -> mealQueueService.sendAddMealMessage(null))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Meal must not be null");
        verifyNoInteractions(rabbitTemplate);
    }

    @Test
    void sendAddMealMessage_zeroUserId_throwsValidationException() {
        Meal meal = validAddMeal();
        meal.setUserID(0);
        assertThatThrownBy(() -> mealQueueService.sendAddMealMessage(meal))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("userID must be positive");
    }

    @Test
    void sendAddMealMessage_zeroMealId_throwsValidationException() {
        Meal meal = validAddMeal();
        meal.setMealID(0);
        assertThatThrownBy(() -> mealQueueService.sendAddMealMessage(meal))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("mealID must be positive");
    }

    @Test
    void sendAddMealMessage_nullMealType_throwsValidationException() {
        Meal meal = validAddMeal();
        meal.setMealType(null);
        assertThatThrownBy(() -> mealQueueService.sendAddMealMessage(meal))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("mealType must not be null");
    }

    @Test
    void sendAddMealMessage_negativeGrammes_throwsValidationException() {
        Meal meal = validAddMeal();
        meal.setGrammes(-10f);
        assertThatThrownBy(() -> mealQueueService.sendAddMealMessage(meal))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("grammes must be positive");
    }

    @Test
    void sendAddMealMessage_zeroGrammes_throwsValidationException() {
        Meal meal = validAddMeal();
        meal.setGrammes(0f);
        assertThatThrownBy(() -> mealQueueService.sendAddMealMessage(meal))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("grammes must be positive");
    }

    @Test
    void sendAddMealMessage_blankTimestamp_throwsValidationException() {
        Meal meal = validAddMeal();
        meal.setTimestamp("  ");
        assertThatThrownBy(() -> mealQueueService.sendAddMealMessage(meal))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("timestamp must not be blank");
    }

    @Test
    void sendAddMealMessage_nullTimestamp_throwsValidationException() {
        Meal meal = validAddMeal();
        meal.setTimestamp(null);
        assertThatThrownBy(() -> mealQueueService.sendAddMealMessage(meal))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("timestamp must not be blank");
    }

    @Test
    void sendAddMealMessage_rabbitMqFails_throwsRuntimeException() {
        doThrow(new RuntimeException("broker down"))
                .when(rabbitTemplate).convertAndSend(any(), any(), (Object) any());

        assertThatThrownBy(() -> mealQueueService.sendAddMealMessage(validAddMeal()))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Failed to send meal to queue");
    }

    // ===================== sendDeleteMealMessage =====================

    @Test
    void sendDeleteMealMessage_validMeal_sendsToQueue() {
        Meal meal = validDeleteMeal();

        mealQueueService.sendDeleteMealMessage(meal);

        ArgumentCaptor<Meal> captor = ArgumentCaptor.forClass(Meal.class);
        verify(rabbitTemplate).convertAndSend(
                eq(RabbitMQConfig.MEALS_EXCHANGE),
                eq(RabbitMQConfig.DELETE_MEAL_ROUTING_KEY),
                captor.capture());
        assertThat(captor.getValue().getId()).isEqualTo(7);
    }

    @Test
    void sendDeleteMealMessage_nullMeal_throwsValidationException() {
        assertThatThrownBy(() -> mealQueueService.sendDeleteMealMessage(null))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Meal must not be null");
    }

    @Test
    void sendDeleteMealMessage_zeroId_throwsValidationException() {
        Meal meal = validDeleteMeal();
        meal.setId(0);
        assertThatThrownBy(() -> mealQueueService.sendDeleteMealMessage(meal))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Meal id must be positive");
    }

    @Test
    void sendDeleteMealMessage_zeroUserId_throwsValidationException() {
        Meal meal = validDeleteMeal();
        meal.setUserID(0);
        assertThatThrownBy(() -> mealQueueService.sendDeleteMealMessage(meal))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("userID must be positive");
    }

    @Test
    void sendDeleteMealMessage_rabbitMqFails_throwsRuntimeException() {
        doThrow(new RuntimeException("broker down"))
                .when(rabbitTemplate).convertAndSend(any(), any(), (Object) any());

        assertThatThrownBy(() -> mealQueueService.sendDeleteMealMessage(validDeleteMeal()))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Failed to send delete request to queue");
    }

    // ===================== helpers =====================

    private Meal validAddMeal() {
        return new Meal(0, 1, 42, MealType.Breakfast, 200f, "2026-02-23T08:00:00");
    }

    private Meal validDeleteMeal() {
        return new Meal(7, 1, 0, null, 0f, null);
    }
}
