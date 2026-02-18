package com.arbybyby.aistep.ai_step_backend.service;

import com.arbybyby.aistep.ai_step_backend.config.RabbitMQConfig;
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
}
