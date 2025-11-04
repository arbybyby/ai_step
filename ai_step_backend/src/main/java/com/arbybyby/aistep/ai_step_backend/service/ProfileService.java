package com.arbybyby.aistep.ai_step_backend.service;

import com.arbybyby.aistep.ai_step_backend.dto.ProfileResponse;
import com.arbybyby.aistep.ai_step_backend.dto.ProfileUpdateRequest;
import com.arbybyby.aistep.ai_step_backend.dto.FlutterProfileUpdateRequest;
import com.arbybyby.aistep.ai_step_backend.models.User;
import com.arbybyby.aistep.ai_step_backend.repositories.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@Transactional
public class ProfileService {
    private static final Logger logger = LoggerFactory.getLogger(ProfileService.class);

    private final UserRepository userRepository;

    @Autowired
    public ProfileService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public ProfileResponse getUserProfile(Long userId) {
        logger.info("Getting profile for user ID: {}", userId);
        
        Optional<User> userOptional = userRepository.findById(userId);
        if (userOptional.isEmpty()) {
            logger.warn("User not found with ID: {}", userId);
            throw new RuntimeException("User not found");
        }

        User user = userOptional.get();
        return mapUserToProfileResponse(user);
    }

    public ProfileResponse updateUserProfile(Long userId, ProfileUpdateRequest updateRequest) {
        logger.info("Updating profile for user ID: {}", userId);
        
        Optional<User> userOptional = userRepository.findById(userId);
        if (userOptional.isEmpty()) {
            logger.warn("User not found with ID: {}", userId);
            throw new RuntimeException("User not found");
        }

        User user = userOptional.get();
        
        // Update only non-null fields
        if (updateRequest.getEmail() != null) {
            user.setEmail(updateRequest.getEmail());
        }
        if (updateRequest.getFirstName() != null) {
            user.setFirstName(updateRequest.getFirstName());
        }
        if (updateRequest.getLastName() != null) {
            user.setLastName(updateRequest.getLastName());
        }
        if (updateRequest.getHeightCm() != null) {
            user.setHeightCm(updateRequest.getHeightCm());
        }
        if (updateRequest.getWeightKg() != null) {
            user.setWeightKg(updateRequest.getWeightKg());
        }
        if (updateRequest.getGender() != null) {
            user.setGender(updateRequest.getGender());
        }
        if (updateRequest.getActivityLevel() != null) {
            user.setActivityLevel(updateRequest.getActivityLevel());
        }
        if (updateRequest.getGoal() != null) {
            user.setGoal(updateRequest.getGoal());
        }
        if (updateRequest.getBirthDate() != null) {
            user.setBirthDate(updateRequest.getBirthDate());
        }
        if (updateRequest.getAge() != null) {
            user.setAge(updateRequest.getAge());
        }
        if (updateRequest.getLocale() != null) {
            user.setLocale(updateRequest.getLocale());
        }
        if (updateRequest.getTimezone() != null) {
            user.setTimezone(updateRequest.getTimezone());
        }
        if (updateRequest.getUnitsPreference() != null) {
            user.setUnitsPreference(updateRequest.getUnitsPreference());
        }

        User savedUser = userRepository.save(user);
        logger.info("Profile updated successfully for user ID: {}", userId);
        
        return mapUserToProfileResponse(savedUser);
    }

    public ProfileResponse updateUserProfileFromFlutter(Long userId, FlutterProfileUpdateRequest flutterRequest) {
        logger.info("Updating profile from Flutter for user ID: {}", userId);
        
        // Конвертируем Flutter DTO в стандартный DTO
        ProfileUpdateRequest updateRequest = convertFlutterToStandard(flutterRequest);
        
        return updateUserProfile(userId, updateRequest);
    }
    
    private ProfileUpdateRequest convertFlutterToStandard(FlutterProfileUpdateRequest flutterRequest) {
        ProfileUpdateRequest request = new ProfileUpdateRequest();
        
        if (flutterRequest.getEmail() != null) {
            request.setEmail(flutterRequest.getEmail().trim());
        }
        if (flutterRequest.getFirstName() != null) {
            request.setFirstName(flutterRequest.getFirstName().trim());
        }
        if (flutterRequest.getLastName() != null) {
            request.setLastName(flutterRequest.getLastName().trim());
        }
        if (flutterRequest.getHeightCm() != null) {
            request.setHeightCm(flutterRequest.getHeightCm());
        }
        if (flutterRequest.getWeightKg() != null) {
            request.setWeightKg(flutterRequest.getWeightKg());
        }
        if (flutterRequest.getGender() != null) {
            request.setGender(flutterRequest.getGender().toLowerCase());
        }
        if (flutterRequest.getActivityLevel() != null) {
            request.setActivityLevel(flutterRequest.getActivityLevel().toLowerCase());
        }
        if (flutterRequest.getGoal() != null) {
            request.setGoal(flutterRequest.getGoal().toLowerCase());
        }
        if (flutterRequest.getBirthDate() != null) {
            request.setBirthDate(flutterRequest.getBirthDate());
        }
        if (flutterRequest.getAge() != null) {
            request.setAge(flutterRequest.getAge());
        }
        if (flutterRequest.getLocale() != null) {
            request.setLocale(flutterRequest.getLocale());
        }
        if (flutterRequest.getTimezone() != null) {
            request.setTimezone(flutterRequest.getTimezone());
        }
        if (flutterRequest.getUnitsPreference() != null) {
            request.setUnitsPreference(flutterRequest.getUnitsPreference().toLowerCase());
        }
        
        return request;
    }

    private ProfileResponse mapUserToProfileResponse(User user) {
        ProfileResponse response = new ProfileResponse();
        response.setId(user.getId());
        response.setEmail(user.getEmail());
        response.setFirstName(user.getFirstName());
        response.setLastName(user.getLastName());
        response.setHeightCm(user.getHeightCm());
        response.setWeightKg(user.getWeightKg());
        response.setGender(user.getGender());
        response.setActivityLevel(user.getActivityLevel());
        response.setGoal(user.getGoal());
        response.setBirthDate(user.getBirthDate());
        response.setAge(user.getAge());
        response.setLocale(user.getLocale());
        response.setTimezone(user.getTimezone());
        response.setUnitsPreference(user.getUnitsPreference());
        return response;
    }
}