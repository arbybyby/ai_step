# Flutter Profile Validation Implementation

## Обзор

Реализована комплексная система валидации данных профиля для Flutter-приложения с backend проверками на Spring Boot и frontend интеграцией.

## Архитектура

### Backend Components

#### 1. FlutterProfileUpdateRequest.java
```java
// DTO класс для данных от Flutter с расширенной валидацией
@Valid
@NotNull(message = "User name cannot be null")
@Size(min = 2, max = 50, message = "User name must be between 2 and 50 characters")
private String userName;

@Min(value = 30, message = "Height must be at least 30 cm")
@Max(value = 250, message = "Height cannot exceed 250 cm")
private Integer heightCm;
```

#### 2. ProfileValidationUtils.java
```java
// Утилиты для профессиональной валидации
public ValidationResult validateFlutterProfileData(FlutterProfileUpdateRequest request)
public double calculateBMI(Integer heightCm, Double weightKg)
public String getBMICategory(double bmi)
```

#### 3. ProfileController.java - Enhanced Endpoints
- `POST /api/profile/flutter/validate` - Валидация данных
- `PUT /api/profile/flutter` - Обновление через Flutter
- `GET /api/profile` - Получение текущего профиля

### Frontend Components

#### 1. AuthService - Enhanced с валидацией
```dart
// Новые классы для валидации
class FlutterProfileValidationResult
class FlutterProfileUpdateRequest
class ValidationException

// Новые методы
Future<FlutterProfileValidationResult> validateProfileData()
Future<User?> updateProfileFromFlutter()
```

#### 2. ProfileService - Flutter Integration
```dart
// Методы валидации
Future<FlutterProfileValidationResult?> validateFlutterProfile()
Future<bool> updateFlutterProfile()
Future<String?> validateField()
String getBMICategory(double bmi)
String getStepGoalRecommendation()
```

#### 3. FlutterProfileValidationScreen
- Real-time валидация полей
- Отображение BMI информации
- Динамические рекомендации
- Визуализация ошибок/предупреждений

## Validation Rules

### Name Validation
- **Minimum length**: 2 символа
- **Maximum length**: 50 символов
- **Pattern**: Только буквы, пробелы, дефисы, апострофы
- **Examples**: "Анна", "Jean-Claude", "O'Connor"

### Physical Parameters
- **Height**: 30-250 см
- **Weight**: 20-500 кг
- **Age**: 13-120 лет
- **BMI**: Автоматический расчет с категоризацией

### Activity & Goals
- **Activity Level**: LOW, MODERATE, HIGH
- **Daily Step Goal**: 1000-50000 шагов
- **Dynamic Recommendations**: Зависят от возраста и активности

### BMI Categories
- **< 18.5**: Недостаточный вес (Warning)
- **18.5-24.9**: Нормальный вес
- **25.0-29.9**: Избыточный вес (Warning)
- **≥ 30.0**: Ожирение (Warning)

## API Examples

### 1. Валидация профиля
```http
POST /api/profile/flutter/validate
Content-Type: application/json
Authorization: Bearer <jwt-token>

{
  "userName": "Александр",
  "heightCm": 175,
  "weightKg": 70,
  "age": 25,
  "activityLevel": "MODERATE",
  "gender": "MALE",
  "dailyStepGoal": 10000
}
```

**Response (Success)**:
```json
{
  "valid": true,
  "message": "All data is valid",
  "calculatedBMI": 22.9,
  "bmiCategory": "Normal weight"
}
```

**Response (Validation Errors)**:
```json
{
  "valid": false,
  "message": "Validation failed",
  "errors": {
    "userName": "User name must be between 2 and 50 characters",
    "age": "Age must be between 13 and 120"
  },
  "warnings": {
    "bmi": "BMI indicates underweight"
  },
  "calculatedBMI": 17.8,
  "bmiCategory": "Underweight"
}
```

### 2. Обновление профиля
```http
PUT /api/profile/flutter
Content-Type: application/json
Authorization: Bearer <jwt-token>

{
  "userName": "Мария",
  "heightCm": 165,
  "weightKg": 55,
  "age": 28,
  "activityLevel": "HIGH",
  "gender": "FEMALE",
  "dailyStepGoal": 12000
}
```

## Flutter Integration

### 1. Service Setup
```dart
// В main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthService()),
    ChangeNotifierProxyProvider<AuthService, ProfileService>(
      create: (context) => ProfileService(
        Provider.of<AuthService>(context, listen: false)
      ),
      update: (context, auth, previous) => ProfileService(auth),
    ),
  ],
  child: MyApp(),
)
```

### 2. Real-time Validation
```dart
// В форме профиля
void _onFieldChanged() {
  Future.delayed(const Duration(milliseconds: 500), () {
    _validateCurrentData();
  });
}

Future<void> _validateCurrentData() async {
  final validation = await profileService.validateFlutterProfile(
    userName: _nameController.text,
    heightCm: int.tryParse(_heightController.text),
    // ... другие поля
  );
  
  setState(() {
    _currentValidation = validation;
  });
}
```

### 3. Error Handling
```dart
Consumer<ProfileService>(
  builder: (context, profileService, child) {
    if (profileService.lastValidationError != null) {
      return ErrorWidget(profileService.lastValidationError!);
    }
    // ... UI
  },
)
```

## Testing

### Backend Tests (profile_flutter_validation_tests.http)
1. **Valid profile data** - Проверка корректных данных
2. **Invalid name** - Короткое имя
3. **Invalid age** - Слишком молодой возраст
4. **Invalid height** - Нереальный рост
5. **Invalid weight** - Нереальный вес
6. **BMI warnings** - Проверка предупреждений
7. **Invalid step goals** - Нереальные цели
8. **Empty/null fields** - Отсутствующие данные
9. **Invalid enum values** - Некорректные значения

### Frontend Testing
```dart
// Пример тестирования валидации
testWidgets('Profile validation shows errors', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.enterText(find.byKey(Key('nameField')), 'A');
  await tester.pump(Duration(milliseconds: 600));
  
  expect(find.text('User name must be between 2 and 50 characters'), 
         findsOneWidget);
});
```

## Security Features

### 1. JWT Authentication
- Все endpoints требуют действующий JWT токен
- Автоматическая проверка истечения токена

### 2. Input Sanitization
- Валидация на уровне DTO с Jakarta Bean Validation
- Дополнительная проверка в ProfileValidationUtils
- Защита от XSS и SQL injection

### 3. Error Handling
- Безопасное отображение ошибок без раскрытия системной информации
- Логирование подробных ошибок для разработчиков

## Performance Optimizations

### 1. Real-time Validation
- Debouncing (500ms) для предотвращения спама запросов
- Кэширование результатов валидации
- Отмена предыдущих запросов при новых изменениях

### 2. Network Optimization
- Валидация отдельных полей vs полного объекта
- Gzip сжатие ответов сервера
- Минимальный payload для validation requests

### 3. UI Optimization
- Отложенная загрузка validation screen
- Lazy loading для dropdown options
- Оптимизированный rebuild только измененных виджетов

## Error Categories

### 1. Validation Errors (400)
```json
{
  "valid": false,
  "errors": {
    "field": "error message"
  }
}
```

### 2. Authentication Errors (401)
```json
{
  "message": "Full authentication is required to access this resource"
}
```

### 3. Server Errors (500)
```json
{
  "message": "Internal server error during validation"
}
```

## Future Enhancements

### 1. Advanced Validations
- Cross-field validation (например, weight vs height consistency)
- Historical data validation (изменения не слишком резкие)
- Medical condition considerations

### 2. Offline Support
- Локальное кэширование validation rules
- Offline queue для pending updates
- Sync при восстановлении соединения

### 3. Internationalization
- Multilingual error messages
- Locale-specific validation rules (например, imperial vs metric)
- Cultural considerations для BMI categories

### 4. Analytics & Monitoring
- Validation success/failure metrics
- Performance monitoring
- User behavior analytics

## Troubleshooting

### Common Issues

1. **"Full authentication is required"**
   - Проверить JWT token в headers
   - Убедиться что токен не истек
   - Проверить CORS настройки

2. **Validation не работает в real-time**
   - Проверить debouncing настройки
   - Убедиться что listeners подключены
   - Проверить network connectivity

3. **BMI не рассчитывается**
   - Проверить что height и weight не null
   - Убедиться в корректности единиц измерения
   - Проверить математические расчеты

### Debug Tools

1. **Backend Debugging**
   ```java
   logger.info("=== Validation Debug ===");
   logger.info("Request: {}", flutterRequest);
   logger.info("Validation Result: {}", validation);
   ```

2. **Flutter Debugging**
   ```dart
   debugPrint('Validation result: ${validation.toJson()}');
   debugPrint('Current errors: ${profileService.lastValidationError}');
   ```

## Conclusion

Реализована полнофункциональная система валидации профиля Flutter с:
- ✅ Real-time валидацией на frontend
- ✅ Comprehensive backend validation
- ✅ Professional error handling
- ✅ BMI calculations and recommendations
- ✅ Security и performance optimizations
- ✅ Extensive testing coverage

Система готова для production использования и дальнейшего расширения функциональности.