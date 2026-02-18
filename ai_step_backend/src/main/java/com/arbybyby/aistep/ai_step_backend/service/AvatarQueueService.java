package com.arbybyby.aistep.ai_step_backend.service;

import com.arbybyby.aistep.ai_step_backend.config.RabbitMQConfig;
import com.arbybyby.aistep.ai_step_backend.dto.AvatarUploadMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AvatarQueueService {

    private static final Logger logger = LoggerFactory.getLogger(AvatarQueueService.class);

    @Autowired
    private RabbitTemplate rabbitTemplate;

    /**
     * Sends avatar upload event to RabbitMQ.
     *
     * @param userId     ID пользователя
     * @param avatarPath путь объекта в MinIO (без адреса сервера)
     */
    public void sendAvatarUploadMessage(Integer userId, String avatarPath) {
        AvatarUploadMessage message = new AvatarUploadMessage(userId, avatarPath);
        try {
            logger.info("Sending avatar upload message to RabbitMQ: userId={}, avatarPath={}", userId, avatarPath);
            rabbitTemplate.convertAndSend(
                    RabbitMQConfig.AVATARS_EXCHANGE,
                    RabbitMQConfig.AVATAR_ROUTING_KEY,
                    message
            );
            logger.info("Successfully sent avatar upload message to RabbitMQ");
        } catch (Exception e) {
            logger.error("Error sending avatar upload message to RabbitMQ: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to send avatar message to queue: " + e.getMessage(), e);
        }
    }
}
