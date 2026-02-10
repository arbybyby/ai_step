package com.arbybyby.aistep.ai_step_backend.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

/**
 * Helper class to get current authenticated user information
 */
public class SecurityUtils {
    
    /**
     * Get the current authenticated user's UserPrincipal
     * @return UserPrincipal or null if not authenticated
     */
    public static UserPrincipal getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof UserPrincipal) {
            return (UserPrincipal) authentication.getPrincipal();
        }
        return null;
    }
    
    /**
     * Get the current authenticated user's ID
     * @return user ID or null if not authenticated
     */
    public static String getCurrentUserId() {
        UserPrincipal user = getCurrentUser();
        return user != null ? user.getUserId() : null;
    }
    
    /**
     * Get the current authenticated user's email
     * @return email or null if not authenticated
     */
    public static String getCurrentUserEmail() {
        UserPrincipal user = getCurrentUser();
        return user != null ? user.getEmail() : null;
    }
}
