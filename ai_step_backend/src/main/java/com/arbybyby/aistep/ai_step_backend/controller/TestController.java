package com.arbybyby.aistep.ai_step_backend.controller;

import com.arbybyby.aistep.ai_step_backend.security.UserPrincipal;
import com.arbybyby.aistep.ai_step_backend.service.StepValidationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api")
public class TestController {
    
    @Autowired
    private StepValidationService stepValidationService;
    
    @GetMapping("/all")
    public String allAccess() {
        return "Public Content.";
    }

    @GetMapping("/user")
    @PreAuthorize("hasRole('USER') or hasRole('MODERATOR') or hasRole('ADMIN')")
    public ResponseEntity<?> userAccess(Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "User Content.");
        response.put("user", Map.of(
            "id", userPrincipal.getId(),
            "email", userPrincipal.getEmail(),
            "firstName", userPrincipal.getFirstName(),
            "lastName", userPrincipal.getLastName()
        ));
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/profile")
    public ResponseEntity<?> getUserProfile(Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }
        
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        
        Map<String, Object> profile = new HashMap<>();
        profile.put("id", userPrincipal.getId());
        profile.put("email", userPrincipal.getEmail());
        profile.put("firstName", userPrincipal.getFirstName());
        profile.put("lastName", userPrincipal.getLastName());
        
        return ResponseEntity.ok(profile);
    }

    @GetMapping("/step-test")
    @PreAuthorize("hasRole('USER') or hasRole('MODERATOR') or hasRole('ADMIN')")
    public ResponseEntity<?> testStepValidation(Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Step validation system is working");
        response.put("user", userPrincipal.getEmail());
        response.put("todaySteps", stepValidationService.getValidStepsForToday(userPrincipal.getId()));
        
        return ResponseEntity.ok(response);
    }
}