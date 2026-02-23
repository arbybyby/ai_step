package com.arbybyby.aistep.ai_step_backend.service;

import com.arbybyby.aistep.ai_step_backend.config.RabbitMQConfig;
import com.arbybyby.aistep.ai_step_backend.dto.AvatarUploadMessage;
import com.arbybyby.aistep.ai_step_backend.exception.ValidationException;
import org.junit.jupiter.api.BeforeEach;
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
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AvatarQueueServiceTest {

    @Mock
    private RabbitTemplate rabbitTemplate;

    @InjectMocks
    private AvatarQueueService avatarQueueService;

    // --- happy path ---

    @Test
    void sendAvatarUploadMessage_validParams_sendsMessage() {
        avatarQueueService.sendAvatarUploadMessage(1, "user_1/avatar.jpg");

        ArgumentCaptor<AvatarUploadMessage> captor = ArgumentCaptor.forClass(AvatarUploadMessage.class);
        verify(rabbitTemplate).convertAndSend(
                eq(RabbitMQConfig.AVATARS_EXCHANGE),
                eq(RabbitMQConfig.AVATAR_ROUTING_KEY),
                captor.capture());

        AvatarUploadMessage sent = captor.getValue();
        assertThat(sent.getUserId()).isEqualTo(1);
        assertThat(sent.getAvatarPath()).isEqualTo("user_1/avatar.jpg");
    }

    // --- userId validation ---

    @Test
    void sendAvatarUploadMessage_nullUserId_throwsValidationException() {
        assertThatThrownBy(() -> avatarQueueService.sendAvatarUploadMessage(null, "user_1/avatar.jpg"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("userId must not be null");

        verifyNoInteractions(rabbitTemplate);
    }

    @Test
    void sendAvatarUploadMessage_zeroUserId_throwsValidationException() {
        assertThatThrownBy(() -> avatarQueueService.sendAvatarUploadMessage(0, "user_0/avatar.jpg"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("userId must be positive");
    }

    @Test
    void sendAvatarUploadMessage_negativeUserId_throwsValidationException() {
        assertThatThrownBy(() -> avatarQueueService.sendAvatarUploadMessage(-5, "user_x/avatar.jpg"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("userId must be positive");
    }

    // --- avatarPath validation ---

    @Test
    void sendAvatarUploadMessage_nullAvatarPath_throwsValidationException() {
        assertThatThrownBy(() -> avatarQueueService.sendAvatarUploadMessage(1, null))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("avatarPath must not be blank");
    }

    @Test
    void sendAvatarUploadMessage_blankAvatarPath_throwsValidationException() {
        assertThatThrownBy(() -> avatarQueueService.sendAvatarUploadMessage(1, "   "))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("avatarPath must not be blank");
    }

    // --- RabbitMQ error propagation ---

    @Test
    void sendAvatarUploadMessage_rabbitMqFails_throwsRuntimeException() {
        doThrow(new RuntimeException("broker down"))
                .when(rabbitTemplate).convertAndSend(any(), any(), (Object) any());

        assertThatThrownBy(() -> avatarQueueService.sendAvatarUploadMessage(1, "user_1/avatar.jpg"))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Failed to send avatar message to queue");
    }
}
