# Meals API - Java to C# Integration via RabbitMQ

## Обзор

Этот модуль предоставляет REST API endpoints для управления приемами пищи (meals). Все данные отправляются через RabbitMQ на backend на C# для обработки.

## Аутентификация

API использует JWT аутентификацию. Режим аутентификации можно переключать через конфигурацию.

### Включение/отключение JWT

В файле `application.properties`:

```properties
# Включить JWT аутентификацию (по умолчанию)
app.security.enabled=true

# Отключить JWT аутентификацию (для разработки/тестирования)
app.security.enabled=false
```

### С включенной аутентификацией (app.security.enabled=true)

- Все `/api/**` endpoints требуют JWT токен в заголовке `Authorization: Bearer <token>`
- `userID` извлекается из токена (из claim `sub`)
- `userID` НЕ нужно указывать в теле запроса

### С отключенной аутентификацией (app.security.enabled=false)

- JWT токен не требуется
- `userID` ОБЯЗАТЕЛЬНО должен быть в теле запроса
- Полезно для локальной разработки и тестирования

> ⚠️ **Важно:** В production всегда используйте `app.security.enabled=true`

Подробнее см. [JWT_AUTH_GUIDE.md](JWT_AUTH_GUIDE.md)

## Архитектура

```
Client → Java API (Spring Boot) → RabbitMQ → C# Backend (.NET)
```

## Модель данных (Meal)

Java модель соответствует C# модели:

```java
public class Meal {
    int Id;                  // C#: int Id
    int UserID;              // C#: int UserID  
    String MealName;         // C#: string MealName
    MealType MealType;       // C#: MealType (enum)
    float Grammes;           // C#: float Grammes
    float Calories;          // C#: float Calories
    float Protein;           // C#: float Protein
    float Carbs;             // C#: float Carbs
    float Fat;               // C#: float Fat
}
```

### MealType Enum

```java
public enum MealType {
    Breakfast,
    Lunch,
    Dinner
}
```

## API Endpoints

### 1. Добавить прием пищи

**POST** `/api/meals/add`

#### С JWT аутентификацией (app.security.enabled=true)

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Request Body:**
```json
{
  "mealName": "Овсяная каша",
  "mealType": "BREAKFAST",
  "grammes": 200.0,
  "calories": 350.5,
  "protein": 12.5,
  "carbs": 58.2,
  "fat": 6.8
}
```

*Примечание: `userID` извлекается из JWT токена*

#### Без JWT аутентификации (app.security.enabled=false)

**Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "userID": 123,
  "mealName": "Овсяная каша",
  "mealType": "BREAKFAST",
  "grammes": 200.0,
  "calories": 350.5,
  "protein": 12.5,
  "carbs": 58.2,
  "fat": 6.8
}
```

*Примечание: `userID` ОБЯЗАТЕЛЕН в теле запроса*

**Response:**
```json
{
  "message": "Meal add request queued successfully",
  "success": true
}
```

### 2. Удалить прием пищи

**DELETE** `/api/meals/delete`

#### С JWT аутентификацией (app.security.enabled=true)

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Request Body:**
```json
{
  "id": 456
}
```

*Примечание: `userID` извлекается из JWT токена*

#### Без JWT аутентификации (app.security.enabled=false)

**Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "id": 456,
  "userID": 123
}
```

*Примечание: `userID` ОБЯЗАТЕЛЕН в теле запроса*

**Response:**
```json
{
  "message": "Meal delete request queued successfully",
  "success": true
}
```

## RabbitMQ Конфигурация

### Exchange
- **Name:** `meals.exchange`
- **Type:** Direct

### Queues

1. **meals.add.queue**
   - **Routing Key:** `meals.add`
   - **Назначение:** Добавление новых приемов пищи

2. **meals.delete.queue**
   - **Routing Key:** `meals.delete`
   - **Назначение:** Удаление приемов пищи

### Формат сообщений

Сообщения отправляются в JSON формате с использованием Jackson:

**Добавление:**
```json
{
  "Id": 0,
  "UserID": 123,
  "MealName": "Овсяная каша",
  "MealType": "Breakfast",
  "Grammes": 200.0,
  "Calories": 350.5,
  "Protein": 12.5,
  "Carbs": 58.2,
  "Fat": 6.8
}
```

**Удаление:**
```json
{
  "Id": 456,
  "UserID": 123,
  "MealName": null,
  "MealType": null,
  "Grammes": 0.0,
  "Calories": 0.0,
  "Protein": 0.0,
  "Carbs": 0.0,
  "Fat": 0.0
}
```

## Настройка

### 1. Зависимости (pom.xml)

```xml
<!-- RabbitMQ -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

### 2. Properties (application.properties)

```properties
# RabbitMQ Configuration
spring.rabbitmq.host=${RABBITMQ_HOST:localhost}
spring.rabbitmq.port=${RABBITMQ_PORT:5672}
spring.rabbitmq.username=${RABBITMQ_USER:guest}
spring.rabbitmq.password=${RABBITMQ_PASSWORD:guest}
```

### 3. Docker Compose

RabbitMQ сервис добавлен в `compose.yaml`:

```yaml
rabbitmq:
  image: rabbitmq:3-management
  ports:
    - "5672:5672"   # AMQP
    - "15672:15672" # Management UI
```

## Запуск

### Локально

1. Запустить RabbitMQ:
```bash
docker-compose up rabbitmq -d
```

2. Запустить Spring Boot приложение:
```bash
./mvnw spring-boot:run
```

### С Docker Compose

```bash
docker-compose up
```

## RabbitMQ Management UI

После запуска RabbitMQ доступен Management UI:
- **URL:** http://localhost:15672
- **Username:** guest
- **Password:** guest

## C# Backend интеграция

### Зависимости для .NET

```xml
<PackageReference Include="RabbitMQ.Client" Version="6.8.1" />
```

### Пример Consumer на C#

```csharp
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

public class MealConsumer
{
    private readonly IConnection _connection;
    private readonly IModel _channel;

    public MealConsumer()
    {
        var factory = new ConnectionFactory() 
        { 
            HostName = "localhost",
            UserName = "guest",
            Password = "guest"
        };
        
        _connection = factory.CreateConnection();
        _channel = _connection.CreateModel();
    }

    public void StartConsuming()
    {
        // Consume add meal messages
        var addConsumer = new EventingBasicConsumer(_channel);
        addConsumer.Received += async (model, ea) =>
        {
            var body = ea.Body.ToArray();
            var message = Encoding.UTF8.GetString(body);
            var meal = JsonSerializer.Deserialize<Meal>(message);
            
            // Process meal addition
            await AddMealToDatabase(meal);
            
            _channel.BasicAck(ea.DeliveryTag, false);
        };
        _channel.BasicConsume(queue: "meals.add.queue", 
                            autoAck: false, 
                            consumer: addConsumer);

        // Consume delete meal messages
        var deleteConsumer = new EventingBasicConsumer(_channel);
        deleteConsumer.Received += async (model, ea) =>
        {
            var body = ea.Body.ToArray();
            var message = Encoding.UTF8.GetString(body);
            var meal = JsonSerializer.Deserialize<Meal>(message);
            
            // Process meal deletion
            await DeleteMealFromDatabase(meal.Id, meal.UserID);
            
            _channel.BasicAck(ea.DeliveryTag, false);
        };
        _channel.BasicConsume(queue: "meals.delete.queue", 
                            autoAck: false, 
                            consumer: deleteConsumer);
    }

    private async Task AddMealToDatabase(Meal meal)
    {
        // Ваша логика добавления в БД
    }

    private async Task DeleteMealFromDatabase(int id, int userId)
    {
        // Ваша логика удаления из БД
    }
}
```

## Тестирование

### cURL примеры

**Добавить прием пищи:**
```bash
curl -X POST http://localhost:8082/api/meals/add \
  -H "Content-Type: application/json" \
  -d '{
    "userID": 1,
    "mealName": "Куриная грудка с рисом",
    "mealType": "Lunch",
    "grammes": 350.0,
    "calories": 450.0,
    "protein": 45.0,
    "carbs": 48.0,
    "fat": 8.5
  }'
```

**Удалить прием пищи:**
```bash
curl -X DELETE http://localhost:8082/api/meals/delete \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "userID": 1
  }'
```

## Логирование

Все операции логируются с использованием SLF4J:
- Входящие запросы
- Отправка в RabbitMQ
- Ошибки обработки

Проверить логи:
```bash
docker-compose logs -f app
```

## Обработка ошибок

При ошибке отправки в RabbitMQ:
- Возвращается HTTP 500
- Ошибка логируется
- Клиент получает описание ошибки

## Структура проекта

```
src/main/java/com/arbybyby/aistep/ai_step_backend/
├── config/
│   └── RabbitMQConfig.java          # Конфигурация RabbitMQ
├── controller/
│   └── MealsController.java         # REST endpoints
├── dto/
│   ├── AddMealRequest.java          # DTO для добавления
│   ├── DeleteMealRequest.java       # DTO для удаления
│   └── MealResponse.java            # DTO ответа
├── models/
│   ├── Meal.java                    # Модель данных
│   └── MealType.java                # Enum типов еды
└── service/
    └── MealQueueService.java        # Сервис отправки в RabbitMQ
```

## Troubleshooting

### RabbitMQ не доступен

Проверьте статус:
```bash
docker-compose ps
```

Перезапустите:
```bash
docker-compose restart rabbitmq
```

### Сообщения не доходят до C#

1. Проверьте наличие очередей в Management UI
2. Убедитесь, что C# consumer запущен
3. Проверьте логи обеих сторон

### Ошибки сериализации

Убедитесь, что:
- JSON property names совпадают (PascalCase)
- Enum values идентичны
- Типы данных совместимы
