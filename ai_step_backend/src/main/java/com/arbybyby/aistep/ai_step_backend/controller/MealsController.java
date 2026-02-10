package com.arbybyby.aistep.ai_step_backend.controller;

import com.arbybyby.aistep.ai_step_backend.dto.AddMealRequest;
import com.arbybyby.aistep.ai_step_backend.dto.DeleteMealRequest;
import com.arbybyby.aistep.ai_step_backend.dto.MealResponse;
import com.arbybyby.aistep.ai_step_backend.models.Meal;
import com.arbybyby.aistep.ai_step_backend.security.SecurityUtils;
import com.arbybyby.aistep.ai_step_backend.service.MealQueueService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/meals")
public class MealsController {
    private static final Logger logger = LoggerFactory.getLogger(MealsController.class);
    
    @Autowired
    private MealQueueService mealQueueService;
    
    @org.springframework.beans.factory.annotation.Value("${app.security.enabled:true}")
    private boolean securityEnabled;

    /**
     * Add a new meal - sends data to RabbitMQ for processing by C# backend
     * POST /api/meals/add
     */
    @PostMapping("/add")
    public ResponseEntity<MealResponse> addMeal(@Valid @RequestBody AddMealRequest request) {
        try {
            Integer userId;
            
            if (securityEnabled) {
                // Get userId from JWT token when security is enabled
                String userIdStr = SecurityUtils.getCurrentUserId();
                if (userIdStr == null) {
                    logger.error("User ID not found in token");
                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                            .body(new MealResponse("User not authenticated", false));
                }
                userId = Integer.parseInt(userIdStr);
            } else {
                // Get userId from request body when security is disabled
                if (request.getUserID() == null) {
                    logger.error("UserID is required in request body when security is disabled");
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .body(new MealResponse("UserID is required", false));
                }
                userId = request.getUserID();
            }
            logger.info("Received add meal request: userId={}, mealName={}, mealType={}", 
                       userId, request.getMealName(), request.getMealType());
            
            // Create Meal object from request (ID will be assigned by C# backend)
            Meal meal = new Meal(
                0, // ID will be assigned by C# backend
                userId, // Use userId from token
                request.getMealName(),
                request.getMealType(),
                request.getGrammes(),
                request.getCalories(),
                request.getProtein(),
                request.getCarbs(),
                request.getFat()
            );
            
            // Send to RabbitMQ
            mealQueueService.sendAddMealMessage(meal);
            
            logger.info("Successfully queued add meal request for userId={}", userId);
            return ResponseEntity.ok(new MealResponse("Meal add request queued successfully", true));
            
        } catch (Exception e) {
            logger.error("Error processing add meal request: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MealResponse("Failed to queue meal: " + e.getMessage(), false));
        }
    }

    /**
     * Delete a meal - sends deletion request to RabbitMQ for processing by C# backend
     * DELETE /api/meals/delete
     */
    @DeleteMapping("/delete")
    public ResponseEntity<MealResponse> deleteMeal(@Valid @RequestBody DeleteMealRequest request) {
        try {
            Integer userId;
            
            if (securityEnabled) {
                // Get userId from JWT token when security is enabled
                String userIdStr = SecurityUtils.getCurrentUserId();
                if (userIdStr == null) {
                    logger.error("User ID not found in token");
                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                            .body(new MealResponse("User not authenticated", false));
                }
                userId = Integer.parseInt(userIdStr);
            } else {
                // Get userId from request body when security is disabled
                if (request.getUserID() == null) {
                    logger.error("UserID is required in request body when security is disabled");
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .body(new MealResponse("UserID is required", false));
                }
                userId = request.getUserID();
            }
            logger.info("Received delete meal request: id={}, userId={}", 
                       request.getId(), userId);
            
            // Create Meal object with only ID and UserID for deletion
            Meal meal = new Meal(
                request.getId(),
                userId, // Use userId from token
                null, // Not needed for deletion
                null, // Not needed for deletion
                0f, 0f, 0f, 0f, 0f // Not needed for deletion
            );
            
            // Send to RabbitMQ
            mealQueueService.sendDeleteMealMessage(meal);
            
            logger.info("Successfully queued delete meal request: id={}, userId={}", 
                       request.getId(), userId);
            return ResponseEntity.ok(new MealResponse("Meal delete request queued successfully", true));
            
        } catch (Exception e) {
            logger.error("Error processing delete meal request: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MealResponse("Failed to queue delete request: " + e.getMessage(), false));
        }
    }
}
