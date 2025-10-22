package com.arbybyby.aistep.ai_step_backend.controller;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import com.arbybyby.aistep.ai_step_backend.dto.AuthResponse;
import com.arbybyby.aistep.ai_step_backend.dto.LoginRequest;
import com.arbybyby.aistep.ai_step_backend.dto.MessageResponse;
import com.arbybyby.aistep.ai_step_backend.dto.RegisterRequest;
import com.arbybyby.aistep.ai_step_backend.models.User;
import com.arbybyby.aistep.ai_step_backend.security.JwtUtils;
import com.arbybyby.aistep.ai_step_backend.security.UserPrincipal;
import com.arbybyby.aistep.ai_step_backend.service.AuthService;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/auth")
public class AuthController {
    @Autowired
    AuthenticationManager authenticationManager;

    @Autowired
    AuthService authService;

    @Autowired
    JwtUtils jwtUtils;

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
            User user = authService.registerUser(signUpRequest);
            
            // Auto-login after registration
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(signUpRequest.getEmail(), signUpRequest.getPassword()));

            SecurityContextHolder.getContext().setAuthentication(authentication);
            String jwt = jwtUtils.generateJwtToken(authentication);

            UserPrincipal userDetails = (UserPrincipal) authentication.getPrincipal();

            return ResponseEntity.ok(new AuthResponse(jwt,
                    userDetails.getId(),
                    userDetails.getEmail(),
                    userDetails.getFirstName(),
                    userDetails.getLastName(),
                    true)); // Assuming email is verified for now
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(new MessageResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Error: Registration failed!"));
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
}
