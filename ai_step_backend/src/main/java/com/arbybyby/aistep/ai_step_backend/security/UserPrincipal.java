package com.arbybyby.aistep.ai_step_backend.security;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Collections;

/**
 * Custom UserDetails implementation for JWT authentication
 */
public class UserPrincipal implements UserDetails {
    private final String userId;
    private final String email;
    
    public UserPrincipal(String userId, String email) {
        this.userId = userId;
        this.email = email;
    }
    
    public String getUserId() {
        return userId;
    }
    
    public String getEmail() {
        return email;
    }
    
    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        // Return empty collection as we don't use role-based authorization
        return Collections.emptyList();
    }
    
    @Override
    public String getPassword() {
        // Not used for JWT authentication
        return null;
    }
    
    @Override
    public String getUsername() {
        return email;
    }
    
    @Override
    public boolean isAccountNonExpired() {
        return true;
    }
    
    @Override
    public boolean isAccountNonLocked() {
        return true;
    }
    
    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }
    
    @Override
    public boolean isEnabled() {
        return true;
    }
}
