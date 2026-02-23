package com.arbybyby.aistep.ai_step_backend.service;

import com.arbybyby.aistep.ai_step_backend.exception.ValidationException;
import io.minio.BucketExistsArgs;
import io.minio.MinioClient;
import io.minio.ObjectWriteResponse;
import io.minio.PutObjectArgs;
import io.minio.RemoveObjectArgs;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MinioServiceTest {

    @Mock
    private MinioClient minioClient;

    @InjectMocks
    private MinioService minioService;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(minioService, "bucketName", "avatars");
    }

    // ===================== uploadAvatar – validation =====================

    @Test
    void uploadAvatar_nullUserId_throwsValidationException() {
        MockMultipartFile file = jpegFile("photo.jpg");

        assertThatThrownBy(() -> minioService.uploadAvatar(null, file))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("userId must be a positive number");
        verifyNoInteractions(minioClient);
    }

    @Test
    void uploadAvatar_zeroUserId_throwsValidationException() {
        MockMultipartFile file = jpegFile("photo.jpg");

        assertThatThrownBy(() -> minioService.uploadAvatar(0, file))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("userId must be a positive number");
    }

    @Test
    void uploadAvatar_negativeUserId_throwsValidationException() {
        MockMultipartFile file = jpegFile("photo.jpg");

        assertThatThrownBy(() -> minioService.uploadAvatar(-1, file))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("userId must be a positive number");
    }

    @Test
    void uploadAvatar_nullFile_throwsValidationException() {
        assertThatThrownBy(() -> minioService.uploadAvatar(1, null))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Avatar file must not be empty");
    }

    @Test
    void uploadAvatar_emptyFile_throwsValidationException() {
        MockMultipartFile emptyFile = new MockMultipartFile(
                "file", "photo.jpg", "image/jpeg", new byte[0]);

        assertThatThrownBy(() -> minioService.uploadAvatar(1, emptyFile))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Avatar file must not be empty");
    }

    // ===================== uploadAvatar – unsupported type =====================

    @Test
    void uploadAvatar_unsupportedFileType_throwsIllegalArgumentException() {
        // Plain text bytes – no image magic bytes
        MockMultipartFile txtFile = new MockMultipartFile(
                "file", "data.txt", "text/plain", "hello world".getBytes());

        assertThatThrownBy(() -> minioService.uploadAvatar(1, txtFile))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Unsupported file type");
    }

    // ===================== uploadAvatar – happy paths =====================

    @Test
    void uploadAvatar_validJpeg_returnsObjectName() throws Exception {
        when(minioClient.bucketExists(any(BucketExistsArgs.class))).thenReturn(true);
        when(minioClient.putObject(any(PutObjectArgs.class))).thenReturn(null);

        String result = minioService.uploadAvatar(42, jpegFile("avatar.jpg"));

        assertThat(result).startsWith("user_42/");
        assertThat(result).endsWith(".jpg");
        verify(minioClient).putObject(any(PutObjectArgs.class));
    }

    @Test
    void uploadAvatar_validPng_returnsObjectName() throws Exception {
        when(minioClient.bucketExists(any(BucketExistsArgs.class))).thenReturn(true);
        when(minioClient.putObject(any(PutObjectArgs.class))).thenReturn(null);

        String result = minioService.uploadAvatar(5, pngFile("avatar.png"));

        assertThat(result).startsWith("user_5/");
        assertThat(result).endsWith(".png");
    }

    @Test
    void uploadAvatar_bucketDoesNotExist_createsBucketThenUploads() throws Exception {
        when(minioClient.bucketExists(any(BucketExistsArgs.class))).thenReturn(false);
        doNothing().when(minioClient).makeBucket(any());
        when(minioClient.putObject(any(PutObjectArgs.class))).thenReturn(null);

        String result = minioService.uploadAvatar(1, jpegFile("avatar.jpg"));

        assertThat(result).isNotBlank();
        verify(minioClient).makeBucket(any());
    }

    // ===================== deleteObject =====================

    @Test
    void deleteObject_blankName_throwsValidationException() {
        assertThatThrownBy(() -> minioService.deleteObject("  "))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("objectName must not be blank");
        verifyNoInteractions(minioClient);
    }

    @Test
    void deleteObject_nullName_throwsValidationException() {
        assertThatThrownBy(() -> minioService.deleteObject(null))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("objectName must not be blank");
    }

    @Test
    void deleteObject_validName_callsMinioRemove() throws Exception {
        doNothing().when(minioClient).removeObject(any(RemoveObjectArgs.class));

        minioService.deleteObject("user_1/avatar.jpg");

        verify(minioClient).removeObject(any(RemoveObjectArgs.class));
    }

    // ===================== helpers =====================

    /** Creates a MockMultipartFile with JPEG magic bytes (FF D8 FF). */
    private MockMultipartFile jpegFile(String filename) {
        byte[] jpegMagic = new byte[]{(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, 0x00, 0x01};
        return new MockMultipartFile("file", filename, "image/jpeg", jpegMagic);
    }

    /** Creates a MockMultipartFile with PNG magic bytes (89 50 4E 47 0D 0A 1A 0A). */
    private MockMultipartFile pngFile(String filename) {
        byte[] pngMagic = new byte[]{
                (byte) 0x89, 'P', 'N', 'G', '\r', '\n', (byte) 0x1A, '\n',
                0x00, 0x01, 0x02, 0x03
        };
        return new MockMultipartFile("file", filename, "image/png", pngMagic);
    }
}
