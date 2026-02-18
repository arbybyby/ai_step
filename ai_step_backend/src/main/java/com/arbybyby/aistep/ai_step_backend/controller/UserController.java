package com.arbybyby.aistep.ai_step_backend.controller;

import com.arbybyby.aistep.ai_step_backend.dto.UserRequest;
import com.arbybyby.aistep.ai_step_backend.dto.UserResponse;
import com.arbybyby.aistep.ai_step_backend.models.User;
import com.arbybyby.aistep.ai_step_backend.service.UserQueueService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/users")
public class UserController {
    private static final Logger logger = LoggerFactory.getLogger(UserController.class);
    
    @Autowired
    private UserQueueService userQueueService;

    /**
     * Submit user data - sends data to RabbitMQ for processing by backend
     * POST /users/submit
     */
    @PostMapping("/submit")
    public ResponseEntity<UserResponse> submitUser(@Valid @RequestBody UserRequest request) {
        try {
            logger.info("Received submit user request: userId={}, email={}", 
                       request.getId(), request.getEmail());
            
            // Create User object from request
            User user = new User(
                request.getId(),
                request.getEmail(),
                request.getFirstName(),
                request.getLastName(),
                request.getAge(),
                request.getHeight(),
                request.getWeight(),
                request.getGender(),
                request.getActivityLevel(),
                request.getGoal(),
                request.getIsVerified(),
                request.getCreatedAt(),
                request.getCalorieGoal(),
                request.getProteinGoal(),
                request.getWaterGoal(),
                request.getStepsGoal()
            );
            
            // Send to RabbitMQ
            userQueueService.sendUserMessage(user);
            
            logger.info("Successfully queued user request for userId={}", request.getId());
            return ResponseEntity.ok(new UserResponse("User request queued successfully", true));
            
        } catch (Exception e) {
            logger.error("Error processing user request: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new UserResponse("Failed to queue user: " + e.getMessage(), false));
        }
    }
}
