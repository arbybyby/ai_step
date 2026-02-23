package com.arbybyby.aistep.ai_step_backend.service;

import com.arbybyby.aistep.ai_step_backend.config.RabbitMQConfig;
import com.arbybyby.aistep.ai_step_backend.exception.ValidationException;
import com.arbybyby.aistep.ai_step_backend.models.Meal;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class MealQueueService {
    private static final Logger logger = LoggerFactory.getLogger(MealQueueService.class);
    
    @Autowired
    private RabbitTemplate rabbitTemplate;
    
    /**
     * Send meal data to add queue
     * @param meal Meal object to add
     */
    public void sendAddMealMessage(Meal meal) {
        validateMealForAdd(meal);
        try {
            logger.info("Sending add meal message to RabbitMQ: userId={}, mealID={}", 
                       meal.getUserID(), meal.getMealID());
            rabbitTemplate.convertAndSend(
                RabbitMQConfig.MEALS_EXCHANGE,
                RabbitMQConfig.ADD_MEAL_ROUTING_KEY,
                meal
            );
            logger.info("Successfully sent add meal message to RabbitMQ");
        } catch (Exception e) {
            logger.error("Error sending add meal message to RabbitMQ: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to send meal to queue: " + e.getMessage(), e);
        }
    }
    
    /**
     * Send meal deletion request to delete queue
     * @param meal Meal object with id and userId for deletion
     */
    public void sendDeleteMealMessage(Meal meal) {
        validateMealForDelete(meal);
        try {
            logger.info("Sending delete meal message to RabbitMQ: id={}, userId={}", 
                       meal.getId(), meal.getUserID());
            rabbitTemplate.convertAndSend(
                RabbitMQConfig.MEALS_EXCHANGE,
                RabbitMQConfig.DELETE_MEAL_ROUTING_KEY,
                meal
            );
            logger.info("Successfully sent delete meal message to RabbitMQ");
        } catch (Exception e) {
            logger.error("Error sending delete meal message to RabbitMQ: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to send delete request to queue: " + e.getMessage(), e);
        }
    }

    private void validateMealForAdd(Meal meal) {
        if (meal == null) {
            throw new ValidationException("Meal must not be null");
        }
        if (meal.getUserID() <= 0) {
            throw new ValidationException("Meal userID must be positive, got: " + meal.getUserID());
        }
        if (meal.getMealID() <= 0) {
            throw new ValidationException("Meal mealID must be positive, got: " + meal.getMealID());
        }
        if (meal.getMealType() == null) {
            throw new ValidationException("Meal mealType must not be null");
        }
        if (meal.getGrammes() <= 0) {
            throw new ValidationException("Meal grammes must be positive, got: " + meal.getGrammes());
        }
        if (meal.getTimestamp() == null || meal.getTimestamp().isBlank()) {
            throw new ValidationException("Meal timestamp must not be blank");
        }
    }

    private void validateMealForDelete(Meal meal) {
        if (meal == null) {
            throw new ValidationException("Meal must not be null");
        }
        if (meal.getId() <= 0) {
            throw new ValidationException("Meal id must be positive, got: " + meal.getId());
        }
        if (meal.getUserID() <= 0) {
            throw new ValidationException("Meal userID must be positive, got: " + meal.getUserID());
        }
    }
}
