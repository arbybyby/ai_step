# AI Step Backend - Step Validation System

## Обзор

Система валидации шагов решает проблему ложных срабатываний при подсчете шагов, когда телефон лежит на столе или находится в неподвижном состоянии.

## Алгоритм фильтрации

Система использует многоуровневую валидацию на основе:

1. **Magnitude акселерометра** - анализ общей силы ускорения
2. **Статичное состояние** - определение неподвижности устройства
3. **Частота шагов** - валидация реалистичной частоты движения
4. **Ориентация устройства** - учет положения телефона
5. **Тип активности** - анализ контекста использования

## API Endpoints

### Отправка данных о шагах

```
POST /api/steps/submit
```

**Request Body:**
```json
{
  "step_count": 1,
  "accelerometer_data": {
    "x": 0.5,
    "y": 9.8,
    "z": 0.2
  },
  "timestamp": "2025-10-28T10:00:00Z",
  "device_orientation": "portrait",
  "activity_type": "walking"
}
```

**Response:**
```json
{
  "success": true,
  "stepData": {
    "id": 123,
    "stepCount": 1,
    "isValidStep": true,
    "confidenceScore": 0.85,
    "timestamp": "2025-10-28T10:00:00Z"
  }
}
```

### Получение шагов за сегодня

```
GET /api/steps/today
```

**Response:**
```json
{
  "date": "2025-10-28",
  "totalSteps": 1250,
  "distance": 0.975,
  "calories": 50.0
}
```

### Статистика по дням

```
GET /api/steps/daily?days=7
```

**Response:**
```json
{
  "period": "7 days",
  "dailyStats": [
    {
      "day": "2025-10-28",
      "totalSteps": 1250,
      "totalDistanceM": 975.0,
      "totalCalories": 50,
      "lastEntryAt": "2025-10-28T15:30:00Z"
    }
  ]
}
```

### Детальные данные

```
GET /api/steps/detailed?startDate=2025-10-28&endDate=2025-10-28&validOnly=true
```

### Статистика валидации

```
GET /api/steps/validation-stats
```

**Response:**
```json
{
  "period": "last 24 hours",
  "totalSteps": 1500,
  "validSteps": 1250,
  "invalidSteps": 250,
  "validationRate": "83%",
  "averageConfidence": 0.78
}
```

### Пакетная отправка

```
POST /api/steps/batch
```

**Request Body:**
```json
[
  {
    "step_count": 1,
    "accelerometer_data": {"x": 0.5, "y": 9.8, "z": 0.2},
    "timestamp": "2025-10-28T10:00:00Z"
  },
  {
    "step_count": 2,
    "accelerometer_data": {"x": 1.2, "y": 9.5, "z": 0.8},
    "timestamp": "2025-10-28T10:00:30Z"
  }
]
```

## Параметры фильтрации

- **MIN_STEP_MAGNITUDE**: 1.5 - минимальная величина ускорения
- **MAX_STEP_MAGNITUDE**: 25.0 - максимальная величина ускорения
- **MIN_TIME_BETWEEN_STEPS_MS**: 200 - минимальное время между шагами
- **STATIC_THRESHOLD**: 0.5 - порог определения статичности
- **Confidence Score**: 0.5 - минимальный порог для валидного шага

## Типы ориентации устройства

- `portrait` - вертикальное положение (высокая уверенность)
- `landscape` - горизонтальное положение (средняя уверенность)
- `flat` - плоское положение (низкая уверенность)
- `face_down` - экраном вниз (низкая уверенность)

## Типы активности

- `walking`, `running`, `jogging` - высокая уверенность
- `still`, `stationary` - очень низкая уверенность
- `vehicle`, `in_vehicle` - низкая уверенность

## Аутентификация

Все endpoints требуют JWT токен в заголовке:
```
Authorization: Bearer <token>
```

## Тестирование

Для проверки работы системы:
```
GET /api/step-test
```

Этот endpoint покажет текущее состояние системы валидации шагов.