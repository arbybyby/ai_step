package com.arbybyby.aistep.ai_step_backend.service;

import com.arbybyby.aistep.ai_step_backend.config.RabbitMQConfig;
import com.arbybyby.aistep.ai_step_backend.exception.ValidationException;
import com.arbybyby.aistep.ai_step_backend.models.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class UserQueueService {
    private static final Logger logger = LoggerFactory.getLogger(UserQueueService.class);
    
    @Autowired
    private RabbitTemplate rabbitTemplate;
    
    /**
     * Send user data to user queue
     * @param user User object to send
     */
    public void sendUserMessage(User user) {
        validateUser(user);
        try {
            logger.info("Sending user message to RabbitMQ: userId={}, email={}", 
                       user.getId(), user.getEmail());
            rabbitTemplate.convertAndSend(
                RabbitMQConfig.USERS_EXCHANGE,
                RabbitMQConfig.USER_ROUTING_KEY,
                user
            );
            logger.info("Successfully sent user message to RabbitMQ");
        } catch (Exception e) {
            logger.error("Error sending user message to RabbitMQ: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to send user to queue: " + e.getMessage(), e);
        }
    }

    private void validateUser(User user) {
        if (user == null) {
            throw new ValidationException("User must not be null");
        }
        if (user.getId() == null || user.getId() <= 0) {
            throw new ValidationException("User id must be a positive number, got: " + user.getId());
        }
        if (user.getEmail() == null || user.getEmail().isBlank()) {
            throw new ValidationException("User email must not be blank");
        }
        if (!user.getEmail().matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
            throw new ValidationException("User email is invalid: " + user.getEmail());
        }
        if (user.getFirstName() == null || user.getFirstName().isBlank()) {
            throw new ValidationException("User firstName must not be blank");
        }
        if (user.getLastName() == null || user.getLastName().isBlank()) {
            throw new ValidationException("User lastName must not be blank");
        }
        if (user.getAge() == null || user.getAge() <= 0) {
            throw new ValidationException("User age must be positive, got: " + user.getAge());
        }
        if (user.getHeight() == null || user.getHeight() <= 0) {
            throw new ValidationException("User height must be positive, got: " + user.getHeight());
        }
        if (user.getWeight() == null || user.getWeight() <= 0) {
            throw new ValidationException("User weight must be positive, got: " + user.getWeight());
        }
        if (user.getGender() == null) {
            throw new ValidationException("User gender must not be null");
        }
        if (user.getActivityLevel() == null) {
            throw new ValidationException("User activityLevel must not be null");
        }
        if (user.getGoal() == null) {
            throw new ValidationException("User goal must not be null");
        }
    }
}
