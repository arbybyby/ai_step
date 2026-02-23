package com.arbybyby.aistep.ai_step_backend.service;

import com.arbybyby.aistep.ai_step_backend.exception.ValidationException;
import io.minio.*;
import io.minio.errors.MinioException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.UUID;

@Service
public class MinioService {

    private static final Logger logger = LoggerFactory.getLogger(MinioService.class);

    @Autowired
    private MinioClient minioClient;

    @Value("${minio.bucket-name}")
    private String bucketName;

    /**
     * Ensures the avatars bucket exists, creating it if necessary.
     */
    public void ensureBucketExists() throws MinioException, IOException, NoSuchAlgorithmException, InvalidKeyException {
        boolean exists = minioClient.bucketExists(BucketExistsArgs.builder().bucket(bucketName).build());
        if (!exists) {
            minioClient.makeBucket(MakeBucketArgs.builder().bucket(bucketName).build());
            logger.info("Created MinIO bucket: {}", bucketName);
        }
    }

    /**
     * Determines the real MIME type from magic bytes.
     * Returns null if the bytes don't match any known image format.
     */
    private String detectContentType(byte[] header) {
        if (header.length >= 3
                && (header[0] & 0xFF) == 0xFF
                && (header[1] & 0xFF) == 0xD8
                && (header[2] & 0xFF) == 0xFF) {
            return "image/jpeg";
        }
        if (header.length >= 8
                && (header[0] & 0xFF) == 0x89
                && header[1] == 'P' && header[2] == 'N' && header[3] == 'G'
                && header[4] == '\r' && header[5] == '\n'
                && (header[6] & 0xFF) == 0x1A && header[7] == '\n') {
            return "image/png";
        }
        if (header.length >= 6
                && header[0] == 'G' && header[1] == 'I' && header[2] == 'F'
                && header[3] == '8'
                && (header[4] == '7' || header[4] == '9')
                && header[5] == 'a') {
            return "image/gif";
        }
        if (header.length >= 12
                && header[0] == 'R' && header[1] == 'I' && header[2] == 'F' && header[3] == 'F'
                && header[8] == 'W' && header[9] == 'E' && header[10] == 'B' && header[11] == 'P') {
            return "image/webp";
        }
        return null;
    }

    /**
     * Uploads an avatar file to MinIO for the given userId.
     * Returns the object key (path inside the bucket, without host).
     */
    public String uploadAvatar(Integer userId, MultipartFile file)
            throws MinioException, IOException, NoSuchAlgorithmException, InvalidKeyException {

        if (userId == null || userId <= 0) {
            throw new ValidationException("userId must be a positive number, got: " + userId);
        }
        if (file == null || file.isEmpty()) {
            throw new ValidationException("Avatar file must not be empty");
        }

        byte[] bytes = file.getBytes();

        // Detect real content type from magic bytes; fall back to declared type
        String detectedType = detectContentType(bytes);
        String declaredType = file.getContentType();
        String contentType = (detectedType != null) ? detectedType : declaredType;

        if (contentType == null || detectedType == null) {
            throw new IllegalArgumentException(
                    "Unsupported file type. Allowed formats: JPEG, PNG, GIF, WebP. Detected: " + declaredType);
        }

        logger.debug("Avatar content-type: declared={}, detected={}", declaredType, detectedType);

        ensureBucketExists();

        String extension = getExtension(file.getOriginalFilename(), contentType);
        String objectName = "user_" + userId + "/" + UUID.randomUUID() + extension;

        try (InputStream inputStream = new ByteArrayInputStream(bytes)) {
            minioClient.putObject(
                    PutObjectArgs.builder()
                            .bucket(bucketName)
                            .object(objectName)
                            .stream(inputStream, bytes.length, -1)
                            .contentType(contentType)
                            .build()
            );
        }

        logger.info("Uploaded avatar for userId={} as {}", userId, objectName);
        return objectName;
    }

    /**
     * Deletes an object from MinIO by its key (path inside the bucket).
     */
    public void deleteObject(String objectName)
            throws MinioException, IOException, NoSuchAlgorithmException, InvalidKeyException {
        if (objectName == null || objectName.isBlank()) {
            throw new ValidationException("objectName must not be blank");
        }
        minioClient.removeObject(
                RemoveObjectArgs.builder()
                        .bucket(bucketName)
                        .object(objectName)
                        .build()
        );
        logger.info("Deleted MinIO object: {}", objectName);
    }

    private String getExtension(String originalFilename, String contentType) {
        if (originalFilename != null && originalFilename.contains(".")) {
            return originalFilename.substring(originalFilename.lastIndexOf('.'));
        }
        return switch (contentType) {
            case "image/jpeg" -> ".jpg";
            case "image/png"  -> ".png";
            case "image/gif"  -> ".gif";
            case "image/webp" -> ".webp";
            default           -> "";
        };
    }
}
