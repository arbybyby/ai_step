# Profile Validation Rules

## Исправлена проблема "Full authentication is required"

### Корень проблемы
Когда валидация данных в ProfileController не проходила, Spring перенаправлял запрос на `/error` endpoint, который требовал аутентификации, но в контексте ошибки аутентификация терялась.

### Решение
1. ✅ **Добавлен обработчик ошибок валидации** в ProfileController
2. ✅ **Разрешен доступ к `/error`** без аутентификации в WebSecurityConfig
3. ✅ **Добавлены тесты с правильными и неправильными данными**

## Правила валидации ProfileUpdateRequest

### heightCm (Double, optional)
- **Минимум**: 50.0 см
- **Максимум**: 300.0 см
- **Ошибка**: `Height must be at least 50 cm` / `Height must be at most 300 cm`

### weightKg (Double, optional)
- **Минимум**: 30.0 кг
- **Максимум**: 500.0 кг
- **Ошибка**: `Weight must be at least 30 kg` / `Weight must be at most 500 kg`

### gender (String, optional)
- **Допустимые значения**: `male`, `female`, `other`
- **Ошибка**: `Gender must be male, female, or other`

### activityLevel (String, optional)
- **Допустимые значения**:
  - `sedentary` - малоподвижный
  - `lightly_active` - слегка активный  
  - `moderately_active` - умеренно активный
  - `very_active` - очень активный
  - `extra_active` - экстра активный
- **Ошибка**: `Activity level must be sedentary, lightly_active, moderately_active, very_active, or extra_active`

### goal (String, optional)
- **Допустимые значения**: `lose`, `maintain`, `gain`
- **Ошибка**: `Goal must be lose, maintain, or gain`

### birthDate (String, optional)
- **Формат**: `YYYY-MM-DD`
- **Пример**: `1990-05-15`
- **Ошибка**: `Birth date must be in YYYY-MM-DD format`

### age (Integer, optional)
- **Минимум**: 13 лет
- **Максимум**: 120 лет
- **Ошибка**: `Age must be at least 13` / `Age must be at most 120`

### unitsPreference (String, optional)
- **Допустимые значения**: `metric`, `imperial`
- **Ошибка**: `Units preference must be metric or imperial`

## Примеры запросов

### ✅ Правильный запрос
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "heightCm": 175.5,
  "weightKg": 70.2,
  "gender": "male",
  "activityLevel": "moderately_active",
  "goal": "maintain",
  "age": 25,
  "birthDate": "1998-05-15",
  "unitsPreference": "metric"
}
```

### ❌ Неправильный запрос (вызовет ошибки валидации)
```json
{
  "heightCm": 12.0,           // Слишком мало (мин. 50)
  "weightKg": 12.0,           // Слишком мало (мин. 30)
  "gender": "unknown",        // Недопустимое значение
  "activityLevel": "moderate", // Неправильное (должно быть moderately_active)
  "goal": "reduce",           // Недопустимое (должно быть lose)
  "age": 5,                   // Слишком мало (мин. 13)
  "birthDate": "15-05-1998",  // Неправильный формат
  "unitsPreference": "SI"     // Недопустимое значение
}
```

### Ответ на ошибку валидации (400 Bad Request)
```json
{
  "error": "Validation failed",
  "details": {
    "heightCm": "Height must be at least 50 cm",
    "weightKg": "Weight must be at least 30 kg", 
    "activityLevel": "Activity level must be sedentary, lightly_active, moderately_active, very_active, or extra_active"
  }
}
```

## Изменения в коде

### ProfileController.java
- ✅ Добавлен `@ExceptionHandler` для `MethodArgumentNotValidException`
- ✅ Возвращает понятные ошибки валидации в формате JSON

### WebSecurityConfig.java
- ✅ Добавлен `.requestMatchers("/error").permitAll()`

### Тестирование
- ✅ Добавлены HTTP тесты с неправильными данными
- ✅ Добавлены HTTP тесты с правильными данными

## Теперь при ошибках валидации:
1. ❌ **Раньше**: "Full authentication is required"
2. ✅ **Теперь**: Понятное сообщение с детальным описанием ошибок валидации