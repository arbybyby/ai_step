package com.arbybyby.aistep.ai_step_backend.controller;

import com.arbybyby.aistep.ai_step_backend.service.AvatarQueueService;
import com.arbybyby.aistep.ai_step_backend.service.MinioService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/users")
public class AvatarController {

    private static final Logger logger = LoggerFactory.getLogger(AvatarController.class);

    @Autowired
    private MinioService minioService;

    @Autowired
    private AvatarQueueService avatarQueueService;

    /**
     * Upload avatar for a user.
     * POST /users/{userId}/avatar
     * Content-Type: multipart/form-data
     * Field name: file
     */
    @PostMapping(value = "/{userId}/avatar", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> uploadAvatar(
            @PathVariable Integer userId,
            @RequestPart("file") MultipartFile file) {

        if (file == null || file.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "message", "File is empty"));
        }

        try {
            String avatarPath = minioService.uploadAvatar(userId, file);
            avatarQueueService.sendAvatarUploadMessage(userId, avatarPath);
            logger.info("Avatar uploaded and queued for userId={}: {}", userId, avatarPath);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "avatarPath", avatarPath,
                    "message", "Avatar uploaded successfully"
            ));
        } catch (IllegalArgumentException e) {
            logger.warn("Invalid file type for userId={}: {}", userId, e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "message", e.getMessage()));
        } catch (Exception e) {
            logger.error("Failed to upload avatar for userId={}: {}", userId, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("success", false, "message", "Failed to upload avatar: " + e.getMessage()));
        }
    }
}
