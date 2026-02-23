package com.arbybyby.aistep.ai_step_backend.service;

import com.arbybyby.aistep.ai_step_backend.config.RabbitMQConfig;
import com.arbybyby.aistep.ai_step_backend.exception.ValidationException;
import com.arbybyby.aistep.ai_step_backend.models.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.amqp.rabbit.core.RabbitTemplate;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserQueueServiceTest {

    @Mock
    private RabbitTemplate rabbitTemplate;

    @InjectMocks
    private UserQueueService userQueueService;

    // --- happy path ---

    @Test
    void sendUserMessage_validUser_sendsToQueue() {
        User user = validUser();

        userQueueService.sendUserMessage(user);

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(rabbitTemplate).convertAndSend(
                eq(RabbitMQConfig.USERS_EXCHANGE),
                eq(RabbitMQConfig.USER_ROUTING_KEY),
                captor.capture());
        assertThat(captor.getValue().getEmail()).isEqualTo("test@example.com");
    }

    // --- null user ---

    @Test
    void sendUserMessage_nullUser_throwsValidationException() {
        assertThatThrownBy(() -> userQueueService.sendUserMessage(null))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("User must not be null");
        verifyNoInteractions(rabbitTemplate);
    }

    // --- id validation ---

    @Test
    void sendUserMessage_nullId_throwsValidationException() {
        User user = validUser();
        user.setId(null);
        assertThatThrownBy(() -> userQueueService.sendUserMessage(user))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("User id must be a positive number");
    }

    @Test
    void sendUserMessage_zeroId_throwsValidationException() {
        User user = validUser();
        user.setId(0);
        assertThatThrownBy(() -> userQueueService.sendUserMessage(user))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("User id must be a positive number");
    }

    // --- email validation ---

    @Test
    void sendUserMessage_blankEmail_throwsValidationException() {
        User user = validUser();
        user.setEmail("  ");
        assertThatThrownBy(() -> userQueueService.sendUserMessage(user))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("email must not be blank");
    }

    @Test
    void sendUserMessage_invalidEmail_throwsValidationException() {
        User user = validUser();
        user.setEmail("not-an-email");
        assertThatThrownBy(() -> userQueueService.sendUserMessage(user))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("email is invalid");
    }

    // --- name validation ---

    @Test
    void sendUserMessage_blankFirstName_throwsValidationException() {
        User user = validUser();
        user.setFirstName("");
        assertThatThrownBy(() -> userQueueService.sendUserMessage(user))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("firstName must not be blank");
    }

    @Test
    void sendUserMessage_blankLastName_throwsValidationException() {
        User user = validUser();
        user.setLastName("  ");
        assertThatThrownBy(() -> userQueueService.sendUserMessage(user))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("lastName must not be blank");
    }

    // --- numeric fields ---

    @Test
    void sendUserMessage_zeroAge_throwsValidationException() {
        User user = validUser();
        user.setAge(0);
        assertThatThrownBy(() -> userQueueService.sendUserMessage(user))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("age must be positive");
    }

    @Test
    void sendUserMessage_negativeHeight_throwsValidationException() {
        User user = validUser();
        user.setHeight(-170.0);
        assertThatThrownBy(() -> userQueueService.sendUserMessage(user))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("height must be positive");
    }

    @Test
    void sendUserMessage_zeroWeight_throwsValidationException() {
        User user = validUser();
        user.setWeight(0.0);
        assertThatThrownBy(() -> userQueueService.sendUserMessage(user))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("weight must be positive");
    }

    // --- enum fields ---

    @Test
    void sendUserMessage_nullGender_throwsValidationException() {
        User user = validUser();
        user.setGender(null);
        assertThatThrownBy(() -> userQueueService.sendUserMessage(user))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("gender must not be null");
    }

    @Test
    void sendUserMessage_nullActivityLevel_throwsValidationException() {
        User user = validUser();
        user.setActivityLevel(null);
        assertThatThrownBy(() -> userQueueService.sendUserMessage(user))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("activityLevel must not be null");
    }

    @Test
    void sendUserMessage_nullGoal_throwsValidationException() {
        User user = validUser();
        user.setGoal(null);
        assertThatThrownBy(() -> userQueueService.sendUserMessage(user))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("goal must not be null");
    }

    // --- RabbitMQ error propagation ---

    @Test
    void sendUserMessage_rabbitMqFails_throwsRuntimeException() {
        doThrow(new RuntimeException("broker down"))
                .when(rabbitTemplate).convertAndSend(any(), any(), (Object) any());

        assertThatThrownBy(() -> userQueueService.sendUserMessage(validUser()))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Failed to send user to queue");
    }

    // --- helper ---

    private User validUser() {
        return new User(
                1,
                "test@example.com",
                "John",
                "Doe",
                25,
                175.0,
                70.0,
                Gender.MALE,
                ActivityLevel.MODERATE,
                FitnessGoal.MAINTAIN_WEIGHT,
                true,
                LocalDateTime.now(),
                2000.0,
                150.0,
                2000.0,
                8000
        );
    }
}
