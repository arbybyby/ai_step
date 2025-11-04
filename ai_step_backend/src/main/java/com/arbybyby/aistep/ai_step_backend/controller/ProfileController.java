package com.arbybyby.aistep.ai_step_backend.controller;

import com.arbybyby.aistep.ai_step_backend.dto.MessageResponse;
import com.arbybyby.aistep.ai_step_backend.dto.ProfileResponse;
import com.arbybyby.aistep.ai_step_backend.dto.ProfileUpdateRequest;
import com.arbybyby.aistep.ai_step_backend.dto.FlutterProfileUpdateRequest;
import com.arbybyby.aistep.ai_step_backend.security.UserPrincipal;
import com.arbybyby.aistep.ai_step_backend.service.ProfileService;
import com.arbybyby.aistep.ai_step_backend.utils.ProfileValidationUtils;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.validation.FieldError;

import java.util.Map;
import java.util.HashMap;

@CrossOrigin(
    origins = {"http://localhost:*", "http://192.168.1.82:*", "https://*"}, 
    allowedHeaders = {"*"}, 
    methods = {RequestMethod.GET, RequestMethod.POST, RequestMethod.PUT, RequestMethod.PATCH, RequestMethod.DELETE, RequestMethod.OPTIONS},
    allowCredentials = "true",
    maxAge = 3600
)
@RestController
@RequestMapping("/api")
public class ProfileController {
    private static final Logger logger = LoggerFactory.getLogger(ProfileController.class);

    private final ProfileService profileService;
    private final ProfileValidationUtils validationUtils;

    @Autowired
    public ProfileController(ProfileService profileService, ProfileValidationUtils validationUtils) {
        this.profileService = profileService;
        this.validationUtils = validationUtils;
    }

    /**
     * Handle preflight OPTIONS requests for CORS
     */
    @RequestMapping(value = "/profile/**", method = RequestMethod.OPTIONS)
    public ResponseEntity<?> handlePreflight() {
        return ResponseEntity.ok().build();
    }

    /**
     * Health check endpoint (no auth required)
     */
    @GetMapping("/health")
    public ResponseEntity<?> healthCheck() {
        logger.info("=== Health check endpoint called ===");
        return ResponseEntity.ok(Map.of(
            "status", "ok",
            "service", "profile-service",
            "timestamp", System.currentTimeMillis()
        ));
    }

    /**
     * Test authentication endpoint
     */
    @GetMapping("/auth-test")
    public ResponseEntity<?> testAuth(Authentication authentication) {
        logger.info("=== Auth test endpoint called ===");
        
        if (authentication == null) {
            logger.warn("Authentication is null");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new MessageResponse("No authentication found"));
        }
        
        logger.info("Authentication principal: {}", authentication.getPrincipal().getClass().getName());
        
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            logger.info("User ID: {}, Email: {}", userPrincipal.getId(), userPrincipal.getEmail());
            
            return ResponseEntity.ok(Map.of(
                "message", "Authentication successful",
                "userId", userPrincipal.getId(),
                "email", userPrincipal.getEmail(),
                "authorities", authentication.getAuthorities()
            ));
        } catch (Exception e) {
            logger.error("Error processing authentication: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Error: " + e.getMessage()));
        }
    }

    /**
     * Get user profile
     */
    @GetMapping("/profile")
    public ResponseEntity<?> getUserProfile(Authentication authentication) {
        try {
            logger.info("=== GET /api/profile ===");
            logger.info("Authentication object: {}", authentication != null ? authentication.getClass().getSimpleName() : "null");
            
            if (authentication == null) {
                logger.warn("Authentication is null - this should not happen if security is properly configured");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(new MessageResponse("Authentication required"));
            }
            
            logger.info("Authentication principal type: {}", authentication.getPrincipal().getClass().getSimpleName());
            
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            logger.info("User ID: {}", userId);
            logger.info("User Email: {}", userPrincipal.getEmail());

            ProfileResponse profile = profileService.getUserProfile(userId);
            logger.info("Profile loaded successfully for user: {}", userId);

            return ResponseEntity.ok(profile);
        } catch (ClassCastException e) {
            logger.error("Cannot cast authentication principal to UserPrincipal: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Authentication error: invalid principal type"));
        } catch (Exception e) {
            logger.error("Error getting profile: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Error: " + e.getMessage()));
        }
    }

    /**
     * Update user profile
     */
    @PutMapping("/profile")
    public ResponseEntity<?> updateUserProfile(@Valid @RequestBody ProfileUpdateRequest updateRequest, 
                                             Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            logger.info("=== PUT /api/profile ===");
            logger.info("User ID: {}", userId);
            logger.info("Update request: firstName={}, lastName={}, heightCm={}, weightKg={}, gender={}", 
                       updateRequest.getFirstName(), updateRequest.getLastName(), 
                       updateRequest.getHeightCm(), updateRequest.getWeightKg(), updateRequest.getGender());

            ProfileResponse updatedProfile = profileService.updateUserProfile(userId, updateRequest);

            return ResponseEntity.ok(updatedProfile);
        } catch (Exception e) {
            logger.error("Error updating profile: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Error: " + e.getMessage()));
        }
    }

    /**
     * Partial update user profile (PATCH)
     */
    @PatchMapping("/profile")
    public ResponseEntity<?> patchUserProfile(@RequestBody ProfileUpdateRequest updateRequest, 
                                            Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            logger.info("=== PATCH /api/profile ===");
            logger.info("User ID: {}", userId);

            ProfileResponse updatedProfile = profileService.updateUserProfile(userId, updateRequest);

            return ResponseEntity.ok(updatedProfile);
        } catch (Exception e) {
            logger.error("Error patching profile: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Error: " + e.getMessage()));
        }
    }

    /**
     * Handle validation errors
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<?> handleValidationExceptions(MethodArgumentNotValidException ex) {
        logger.warn("Validation errors: {}", ex.getMessage());
        
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach((error) -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });

        Map<String, Object> response = new HashMap<>();
        response.put("error", "Validation failed");
        response.put("details", errors);
        
        return ResponseEntity.badRequest().body(response);
    }

    /**
     * Flutter-specific profile update endpoint with enhanced validation
     */
    @PutMapping("/flutter/profile")
    public ResponseEntity<?> updateUserProfileFromFlutter(@Valid @RequestBody FlutterProfileUpdateRequest flutterRequest, 
                                                        Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            logger.info("=== PUT /api/flutter/profile ===");
            logger.info("User ID: {}", userId);
            logger.info("Flutter update request: firstName={}, lastName={}, heightCm={}, weightKg={}, gender={}", 
                       flutterRequest.getFirstName(), flutterRequest.getLastName(), 
                       flutterRequest.getHeightCm(), flutterRequest.getWeightKg(), flutterRequest.getGender());

            ProfileResponse updatedProfile = profileService.updateUserProfileFromFlutter(userId, flutterRequest);

            return ResponseEntity.ok(updatedProfile);
        } catch (Exception e) {
            logger.error("Error updating profile from Flutter: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Error: " + e.getMessage()));
        }
    }

    /**
     * Flutter-specific profile validation endpoint
     */
    @PostMapping("/flutter/validate")
    public ResponseEntity<?> validateProfileData(@Valid @RequestBody FlutterProfileUpdateRequest flutterRequest, 
                                               Authentication authentication) {
        try {
            logger.info("=== POST /api/flutter/validate ===");
            
            // Используем профессиональную валидацию
            ProfileValidationUtils.ValidationResult validation = validationUtils.validateFlutterProfileData(flutterRequest);
            
            Map<String, Object> response = new HashMap<>();
            response.put("valid", validation.isValid());
            
            if (validation.hasErrors()) {
                response.put("errors", validation.getErrors());
            }
            
            if (validation.hasWarnings()) {
                response.put("warnings", validation.getWarnings());
            }
            
            // Добавляем полезную информацию
            if (flutterRequest.getHeightCm() != null && flutterRequest.getWeightKg() != null) {
                double bmi = validationUtils.calculateBMI(flutterRequest.getHeightCm(), flutterRequest.getWeightKg());
                response.put("calculatedBMI", Math.round(bmi * 10.0) / 10.0);
                response.put("bmiCategory", validationUtils.getBMICategory(bmi));
            }
            
            if (validation.isValid()) {
                response.put("message", "All data is valid");
                return ResponseEntity.ok(response);
            } else {
                response.put("message", "Validation failed");
                return ResponseEntity.badRequest().body(response);
            }
            
        } catch (Exception e) {
            logger.error("Error validating profile data from Flutter: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Validation error: " + e.getMessage()));
        }
    }
}