# Google Sign-In Setup Guide for AI Step

This guide will help you set up Google Sign-In authentication for the AI Step application.

## Backend Configuration

### 1. Dependencies Added
The following dependencies have been added to `pom.xml`:
- `google-api-client` (2.7.0)
- `google-oauth-client` (1.36.0) 
- `google-auth-library-oauth2-http` (1.29.0)

### 2. Database Changes
- Added `google_id` column to `users` table
- Run the migration: `src/main/resources/google_signin_migration.sql`

### 3. Backend Endpoints
- **POST** `/auth/google` - Authenticate with Google ID token

### 4. Configuration
Set the Google Client ID in `application.properties`:
```properties
google.client.id=YOUR_GOOGLE_CLIENT_ID
```

## Frontend Configuration

### 1. Dependencies
Google Sign-In plugin is already included in `pubspec.yaml`:
```yaml
google_sign_in: ^6.2.1
```

### 2. Environment Variables
Set the Google Client ID:
```dart
const String googleClientId = String.fromEnvironment(
  'GOOGLE_CLIENT_ID',
  defaultValue: 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com',
);
```

### 3. Android Configuration

#### SHA-1 Certificate Fingerprint
You need to get your SHA-1 certificate fingerprint for Android:

**For Debug (Development):**
```bash
cd android
./gradlew signingReport
```
Look for the SHA1 fingerprint under `Variant: debug`

**For Release:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### Google Console Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Google Sign-In API
4. Go to "Credentials" 
5. Create OAuth 2.0 Client IDs:
   - **Android:** Use your SHA-1 fingerprint and package name `com.example.ai_step_frontend`
   - **Web:** For web support
   - **iOS:** For iOS support (if needed)

### 4. iOS Configuration (if needed)
Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

## Testing

### 1. Backend Testing
Start the backend and test the endpoint:
```bash
curl -X POST http://localhost:8080/auth/google \
  -H "Content-Type: application/json" \
  -d '{"idToken":"YOUR_GOOGLE_ID_TOKEN"}'
```

### 2. Frontend Testing
Use the test widget provided in `lib/auth/google_signin_test.dart` to test the full flow.

### 3. Database Migration
If you have an existing database, run the migration:
```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR(255) UNIQUE;
```

## Security Notes

1. **Never commit real Client IDs** to version control
2. Use environment variables for production
3. Validate all tokens on the backend
4. The Google Client ID in the code is a placeholder - replace with your own
5. Ensure HTTPS is used in production

## Troubleshooting

### Common Issues:
1. **"Sign-in failed"** - Check SHA-1 certificate fingerprint matches Google Console
2. **"Invalid token"** - Ensure Client ID matches between frontend and backend
3. **"Network error"** - Check if backend is running and endpoint is accessible
4. **"Not configured"** - Verify GOOGLE_CLIENT_ID is set correctly

### Debug Steps:
1. Check logs in Android Studio/Xcode
2. Verify network connectivity
3. Test with a simple HTTP client first
4. Use the provided test widget to isolate issues

## Production Deployment

1. Generate release keystore for Android
2. Get SHA-1 for release keystore
3. Update Google Console with release credentials
4. Set production Google Client ID
5. Enable HTTPS on backend
6. Update CORS settings if needed

## Files Modified/Created

### Backend:
- `pom.xml` - Added Google OAuth dependencies
- `AuthController.java` - Added `/auth/google` endpoint
- `GoogleSignInRequest.java` - New DTO
- `GoogleTokenVerificationService.java` - New service
- `AuthService.java` - Added Google user methods
- `User.java` - Added googleId field
- `init.sql` - Added google_id column
- `application.properties` - Added Google config
- `google_signin_migration.sql` - Migration script

### Frontend:
- `google_signin_test.dart` - Test widget
- `strings.xml` - Android configuration
- Existing auth screens already have Google Sign-In buttons

The Google Sign-In functionality is now ready for testing and development!