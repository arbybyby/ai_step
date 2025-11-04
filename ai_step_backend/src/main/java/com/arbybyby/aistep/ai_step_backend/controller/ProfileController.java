package com.arbybyby.aistep.ai_step_backend.controller;

import com.arbybyby.aistep.ai_step_backend.dto.MessageResponse;
import com.arbybyby.aistep.ai_step_backend.dto.ProfileResponse;
import com.arbybyby.aistep.ai_step_backend.dto.ProfileUpdateRequest;
import com.arbybyby.aistep.ai_step_backend.security.UserPrincipal;
import com.arbybyby.aistep.ai_step_backend.service.ProfileService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.RequestMethod;

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

    @Autowired
    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    /**
     * Handle preflight OPTIONS requests for CORS
     */
    @RequestMapping(value = "/profile/**", method = RequestMethod.OPTIONS)
    public ResponseEntity<?> handlePreflight() {
        return ResponseEntity.ok().build();
    }

    /**
     * Get user profile
     */
    @GetMapping("/profile")
    public ResponseEntity<?> getUserProfile(Authentication authentication) {
        try {
            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            Long userId = userPrincipal.getId();

            logger.info("=== GET /api/profile ===");
            logger.info("User ID: {}", userId);

            ProfileResponse profile = profileService.getUserProfile(userId);

            return ResponseEntity.ok(profile);
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
}