package com.arbybyby.aistep.ai_step_backend.controller;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import com.arbybyby.aistep.ai_step_backend.dto.AuthResponse;
import com.arbybyby.aistep.ai_step_backend.dto.GoogleSignInRequest;
import com.arbybyby.aistep.ai_step_backend.dto.LoginRequest;
import com.arbybyby.aistep.ai_step_backend.dto.MessageResponse;
import com.arbybyby.aistep.ai_step_backend.dto.RegisterRequest;
import com.arbybyby.aistep.ai_step_backend.models.User;
import com.arbybyby.aistep.ai_step_backend.security.JwtUtils;
import com.arbybyby.aistep.ai_step_backend.security.UserPrincipal;
import com.arbybyby.aistep.ai_step_backend.service.AuthService;
import com.arbybyby.aistep.ai_step_backend.service.GoogleTokenVerificationService;

import java.util.HashMap;
import java.util.Map;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/auth")
public class AuthController {
    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);
    
    @Autowired
    AuthenticationManager authenticationManager;

    @Autowired
    AuthService authService;

    @Autowired
    JwtUtils jwtUtils;
    
    @Autowired
    GoogleTokenVerificationService googleTokenVerificationService;

    @PostMapping("/signin")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword()));

            SecurityContextHolder.getContext().setAuthentication(authentication);
            String jwt = jwtUtils.generateJwtToken(authentication);

            UserPrincipal userDetails = (UserPrincipal) authentication.getPrincipal();

            return ResponseEntity.ok(new AuthResponse(jwt,
                    userDetails.getId(),
                    userDetails.getEmail(),
                    userDetails.getFirstName(),
                    userDetails.getLastName(),
                    true)); // Assuming email is verified for now
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new MessageResponse("Error: Invalid email or password!"));
        }
    }

    @PostMapping("/signup")
    public ResponseEntity<?> registerUser(@Valid @RequestBody RegisterRequest signUpRequest) {
        try {
            logger.info("Attempting to register user with email: {}", signUpRequest.getEmail());
            
            User user = authService.registerUser(signUpRequest);
            logger.info("User registered successfully with ID: {}", user.getId());
            
            // Auto-login after registration
            logger.info("Attempting auto-login for user: {}", signUpRequest.getEmail());
            try {
                Authentication authentication = authenticationManager.authenticate(
                        new UsernamePasswordAuthenticationToken(signUpRequest.getEmail(), signUpRequest.getPassword()));

                SecurityContextHolder.getContext().setAuthentication(authentication);
                String jwt = jwtUtils.generateJwtToken(authentication);

                UserPrincipal userDetails = (UserPrincipal) authentication.getPrincipal();
                logger.info("Auto-login successful for user: {}", signUpRequest.getEmail());

                return ResponseEntity.ok(new AuthResponse(jwt,
                        userDetails.getId(),
                        userDetails.getEmail(),
                        userDetails.getFirstName(),
                        userDetails.getLastName(),
                        true)); // Assuming email is verified for now
            } catch (Exception authException) {
                logger.error("Auto-login failed after registration: {}", authException.getMessage());
                // Registration succeeded but auto-login failed, return success message
                return ResponseEntity.ok(new MessageResponse("User registered successfully! Please sign in."));
            }
            
        } catch (IllegalArgumentException e) {
            logger.error("Registration failed with IllegalArgumentException: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(new MessageResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("Registration failed with exception: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Error: Registration failed! Details: " + e.getMessage()));
        }
    }

    @PostMapping("/google")
    public ResponseEntity<?> googleSignIn(@Valid @RequestBody GoogleSignInRequest googleRequest) {
        try {
            logger.info("Attempting Google sign-in with token");
            
            // Verify the Google ID token
            var payload = googleTokenVerificationService.verifyToken(googleRequest.getIdToken());
            if (payload == null) {
                logger.warn("Invalid Google ID token");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(new MessageResponse("Invalid Google ID token"));
            }

            String email = payload.getEmail();
            String firstName = (String) payload.get("given_name");
            String lastName = (String) payload.get("family_name");
            String googleId = payload.getSubject();

            logger.info("Google token verified for email: {}", email);

            // Find or create user
            User user = authService.findOrCreateGoogleUser(email, firstName, lastName, googleId);
            
            // Create authentication token manually for Google users
            String jwt = jwtUtils.generateTokenFromEmail(user.getEmail());

            logger.info("Google sign-in successful for user: {}", email);

            return ResponseEntity.ok(new AuthResponse(jwt,
                    user.getId(),
                    user.getEmail(),
                    user.getFirstName(),
                    user.getLastName(),
                    user.getEmailVerified() != null ? user.getEmailVerified() : true));

        } catch (Exception e) {
            logger.error("Google sign-in failed: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Google sign-in failed"));
        }
    }

    // Legacy endpoint for backward compatibility
    @PostMapping("/register")
    public ResponseEntity<String> register(@RequestBody User user) {
        try {
            authService.addUser(user);
            ResponseEntity<String> response = new ResponseEntity<String>(HttpStatus.CREATED);
            response.getHeaders().add("Access-Control-Allow-Origin", "*");
            response.getHeaders().add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization");
            response.getHeaders().add("Access-Control-Allow-Credentials", "true");
            response.getHeaders().add("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS,HEAD");

            return response;
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/validate")
    public ResponseEntity<?> validateToken(HttpServletRequest request) {
        try {
            String authHeader = request.getHeader("Authorization");
            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                String jwt = authHeader.substring(7);
                if (jwtUtils.validateJwtToken(jwt)) {
                    return ResponseEntity.ok(new MessageResponse("Token is valid"));
                }
            }
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new MessageResponse("Invalid token"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new MessageResponse("Token validation failed"));
        }
    }

    @GetMapping("/test/{email}")
    public ResponseEntity<User> getUserByEmail(@PathVariable String email) {
        User user = authService.getUserByEmail(email);
        if (user != null) {
            return ResponseEntity.ok(user);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        }
    }

    @GetMapping("/google/config")
    public ResponseEntity<?> getGoogleConfig() {
        try {
            // Получаем текущую конфигурацию Google OAuth
            String configuredClientId = googleTokenVerificationService.getClientId();
            
            Map<String, Object> config = new HashMap<>();
            config.put("clientId", configuredClientId);
            config.put("isConfigured", configuredClientId != null && !configuredClientId.isEmpty());
            config.put("isPlaceholder", configuredClientId != null && configuredClientId.contains("37802022899"));
            config.put("timestamp", System.currentTimeMillis());
            
            return ResponseEntity.ok(config);
        } catch (Exception e) {
            logger.error("Error getting Google config: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Error retrieving Google configuration"));
        }
    }
}
