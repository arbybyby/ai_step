package com.arbybyby.aistep.ai_step_backend.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Collections;

@Service
public class GoogleTokenVerificationService {
    private static final Logger logger = LoggerFactory.getLogger(GoogleTokenVerificationService.class);
    
    @Value("${google.client.id:37802022899-a4o3o6qfoglpa0vju8amoubvpkg3ncjk.apps.googleusercontent.com}")
    private String clientId;

    public GoogleIdToken.Payload verifyToken(String idTokenString) {
        try {
            GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(
                    new NetHttpTransport(),
                    GsonFactory.getDefaultInstance())
                    .setAudience(Collections.singletonList(clientId))
                    .build();

            GoogleIdToken idToken = verifier.verify(idTokenString);
            if (idToken != null) {
                GoogleIdToken.Payload payload = idToken.getPayload();
                logger.info("Google token verified successfully for email: {}", payload.getEmail());
                return payload;
            } else {
                logger.warn("Invalid Google ID token");
                return null;
            }
        } catch (Exception e) {
            logger.error("Error verifying Google token: {}", e.getMessage());
            return null;
        }
    }
}