package com.arbybyby.aistep.ai_step_backend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.arbybyby.aistep.ai_step_backend.dto.RegisterRequest;
import com.arbybyby.aistep.ai_step_backend.models.User;
import com.arbybyby.aistep.ai_step_backend.repositories.UserRepository;

import java.time.Instant;

@Service
public class AuthService {
    private static final Logger logger = LoggerFactory.getLogger(AuthService.class);
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Autowired
    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public User registerUser(RegisterRequest registerRequest) {
        logger.info("Starting registration for email: {}", registerRequest.getEmail());
        
        if (userRepository.findByEmail(registerRequest.getEmail()).isPresent()) {
            logger.warn("Registration failed: Email already exists: {}", registerRequest.getEmail());
            throw new IllegalArgumentException("Error: Email is already taken!");
        }

        // Create new user's account
        User user = new User();
        user.setEmail(registerRequest.getEmail());
        user.setFirstName(registerRequest.getFirstName());
        user.setLastName(registerRequest.getLastName());
        user.setPassword(passwordEncoder.encode(registerRequest.getPassword()));
        
        if (registerRequest.getLocale() != null) {
            user.setLocale(registerRequest.getLocale());
        }
        
        if (registerRequest.getTimezone() != null) {
            user.setTimezone(registerRequest.getTimezone());
        }
        
        if (registerRequest.getUnitsPreference() != null) {
            user.setUnitsPreference(registerRequest.getUnitsPreference());
        }

        user.setCreatedAt(Instant.now());
        user.setUpdatedAt(Instant.now());

        logger.info("Saving user to database: {}", registerRequest.getEmail());
        User savedUser = userRepository.save(user);
        logger.info("User saved successfully with ID: {}", savedUser.getId());
        
        return savedUser;
    }

    public void addUser(User user) {
        if (user.getEmail() == null || user.getEmail().isEmpty()) {
            throw new IllegalArgumentException("Email cannot be null or empty");
        }

        if (user.getFirstName() == null || user.getFirstName().isEmpty()) {
            throw new IllegalArgumentException("Name cannot be null or empty");
        }

        if (user.getPassword() == null || user.getPassword().isEmpty()) {
            throw new IllegalArgumentException("Password hash cannot be null or empty");
        }

        if (userRepository.findByEmail(user.getEmail()).isPresent()) {
            throw new IllegalArgumentException("User with this email already exists");
        }

        userRepository.save(user);
    }

    public User getUserByEmail(String email) {
        return userRepository.findByEmail(email).orElse(null);
    }

    public User findOrCreateGoogleUser(String email, String firstName, String lastName, String googleId) {
        logger.info("Finding or creating Google user with email: {}", email);
        
        // Try to find existing user by email
        var existingUser = userRepository.findByEmail(email);
        if (existingUser.isPresent()) {
            User user = existingUser.get();
            // Update Google ID if it's not set
            if (user.getGoogleId() == null || user.getGoogleId().isEmpty()) {
                user.setGoogleId(googleId);
                user.setUpdatedAt(Instant.now());
                userRepository.save(user);
                logger.info("Updated existing user with Google ID: {}", email);
            }
            return user;
        }

        // Create new user for Google sign-in
        User newUser = new User();
        newUser.setEmail(email);
        newUser.setFirstName(firstName);
        newUser.setLastName(lastName);
        newUser.setGoogleId(googleId);
        newUser.setEmailVerified(true); // Google users are pre-verified
        newUser.setCreatedAt(Instant.now());
        newUser.setUpdatedAt(Instant.now());
        
        // Generate a random password for Google users (they won't use it)
        String randomPassword = generateRandomPassword();
        newUser.setPassword(passwordEncoder.encode(randomPassword));

        User savedUser = userRepository.save(newUser);
        logger.info("Created new Google user with ID: {}", savedUser.getId());
        return savedUser;
    }
    
    private String generateRandomPassword() {
        // Generate a random password for Google users
        return java.util.UUID.randomUUID().toString();
    }
}
