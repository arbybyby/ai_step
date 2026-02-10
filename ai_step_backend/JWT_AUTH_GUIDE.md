# JWT Authentication Testing Guide

## Switching Between Authenticated and Non-Authenticated Modes

### Enable/Disable JWT Authentication

Edit `src/main/resources/application.properties`:

```properties
# Enable JWT authentication (default)
app.security.enabled=true

# Disable JWT authentication (for development/testing)
app.security.enabled=false
```

After changing this setting, restart the application.

---

## Testing with JWT Authentication ENABLED

When `app.security.enabled=true`, all `/api/**` endpoints require a valid JWT token.

### Add Meal (with JWT)
```http
POST http://localhost:8082/api/meals/add
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "mealName": "Chicken breast",
  "mealType": "LUNCH",
  "grammes": 150.0,
  "calories": 165.0,
  "protein": 31.0,
  "carbs": 0.0,
  "fat": 3.6
}
```

**Note:** `userID` is NOT in the request body - it's extracted from the JWT token.

### Delete Meal (with JWT)
```http
DELETE http://localhost:8082/api/meals/delete
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "id": 1
}
```

**Note:** `userID` is NOT in the request body - it's extracted from the JWT token.

### Expected Response (Missing/Invalid Token)
```json
{
  "status": 401,
  "error": "Unauthorized",
  "message": "Authentication token is missing or invalid",
  "path": "/api/meals/add"
}
```

---

## Testing with JWT Authentication DISABLED

When `app.security.enabled=false`, endpoints can be accessed without a JWT token, but **userID must be included in the request body**.

### Add Meal (without JWT)
```http
POST http://localhost:8082/api/meals/add
Content-Type: application/json

{
  "userID": 1,
  "mealName": "Chicken breast",
  "mealType": "LUNCH",
  "grammes": 150.0,
  "calories": 165.0,
  "protein": 31.0,
  "carbs": 0.0,
  "fat": 3.6
}
```

**Note:** `userID` IS required in the request body when security is disabled.

### Delete Meal (without JWT)
```http
DELETE http://localhost:8082/api/meals/delete
Content-Type: application/json

{
  "id": 1,
  "userID": 1
}
```

**Note:** `userID` IS required in the request body when security is disabled.

### Expected Response (Missing userID)
```json
{
  "message": "UserID is required",
  "success": false
}
```

---

## JWT Token Structure

Your JWT tokens should contain these claims (matching your C# implementation):

```json
{
  "sub": "123",           // User ID (string)
  "email": "user@example.com",
  "jti": "unique-token-id",
  "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier": "123"
}
```

The Java backend extracts:
- `userId` from the `sub` claim
- `email` from the `email` claim

---

## Quick Test Commands

### Check current security status
Look for this log line on startup:
```
Security enabled: true/false
```

### With curl (JWT enabled)
```bash
curl -X POST http://localhost:8082/api/meals/add \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "mealName": "Test Meal",
    "mealType": "LUNCH",
    "grammes": 100.0,
    "calories": 200.0,
    "protein": 20.0,
    "carbs": 10.0,
    "fat": 5.0
  }'
```

### With curl (JWT disabled)
```bash
curl -X POST http://localhost:8082/api/meals/add \
  -H "Content-Type: application/json" \
  -d '{
    "userID": 1,
    "mealName": "Test Meal",
    "mealType": "LUNCH",
    "grammes": 100.0,
    "calories": 200.0,
    "protein": 20.0,
    "carbs": 10.0,
    "fat": 5.0
  }'
```

---

## Recommendations

⚠️ **Production:** Always set `app.security.enabled=true` in production environments.

✅ **Development:** You can set `app.security.enabled=false` for easier local testing without needing to generate JWT tokens.

🔄 **Remember:** After changing the security setting, you must restart the Spring Boot application for changes to take effect.
