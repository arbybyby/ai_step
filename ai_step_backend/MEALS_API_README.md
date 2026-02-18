# Meals API - Java to C# Integration via RabbitMQ

## Обзор

Этот модуль предоставляет REST API endpoints для управления приемами пищи (meals) и данными пользователей (users). Все данные отправляются через RabbitMQ на backend на C# для обработки.

> **Note:** Endpoint URLs НЕ содержат `/api` префикс, т.к. в приложении не установлен `server.servlet.context-path=/api`. Используйте `/users/submit`, `/meals/add`, `/meals/delete` вместо `/api/users/submit` и т.д.

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

### 1. Отправить данные пользователя

**POST** `/users/submit`

#### Request Body:
```json
{
  "id": 123,
  "email": "user@example.com",
  "firstName": "Alex",
  "lastName": "Ivanov",
  "age": 28,
  "height": 180.0,
  "weight": 75.5,
  "gender": "male",
  "activityLevel": "moderate",
  "goal": "maintain",
  "isVerified": true,
  "createdAt": "2026-02-17T10:15:30.000Z",
  "calorieGoal": 2200.0,
  "proteinGoal": 150.0,
  "waterGoal": 2.5,
  "stepsGoal": 10000
}
```

**Response:**
```json
{
  "message": "User request queued successfully",
  "success": true
}
```

### 2. Добавить прием пищи

**POST** `/meals/add`

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

### 3. Удалить прием пищи

**DELETE** `/meals/delete`

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

### Exchanges
- **Name:** `meals.exchange` - Type: Direct (для meals)
- **Name:** `users.exchange` - Type: Topic (для users)

### Queues

#### Для Meals:

1. **meals.add.queue**
   - **Routing Key:** `meals.add`
   - **Назначение:** Добавление новых приемов пищи

2. **meals.delete.queue**
   - **Routing Key:** `meals.delete`
   - **Назначение:** Удаление приемов пищи

#### Для Users:

3. **users.queue**
   - **Routing Key:** `users.submit`
   - **Exchange:** `users.exchange`
   - **Назначение:** Отправка и обновление данных пользователя

### Формат сообщений

Сообщения отправляются в JSON формате с использованием Jackson:

**User:**
```json
{
  "id": 123,
  "email": "user@example.com",
  "firstName": "Alex",
  "lastName": "Ivanov",
  "age": 28,
  "height": 180.0,
  "weight": 75.5,
  "gender": "male",
  "activityLevel": "moderate",
  "goal": "maintain",
  "isVerified": true,
  "createdAt": "2026-02-17T10:15:30.000Z",
  "calorieGoal": 2200.0,
  "proteinGoal": 150.0,
  "waterGoal": 2.5,
  "stepsGoal": 10000
}
```

**Добавление Meal:**
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

**Удаление Meal:**
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

### Важно: RabbitMQ Setup

**Exchange, Queues и Bindings создаются вручную в RabbitMQ**, а не автоматически приложением.

Создайте следующую инфраструктуру через RabbitMQ Management UI или rabbitmqadmin:

**Meals:**
```bash
rabbitmqadmin declare exchange name=meals.exchange type=direct durable=true
rabbitmqadmin declare queue name=meals.add.queue durable=true
rabbitmqadmin declare queue name=meals.delete.queue durable=true
rabbitmqadmin declare binding source=meals.exchange destination=meals.add.queue routing_key=meals.add
rabbitmqadmin declare binding source=meals.exchange destination=meals.delete.queue routing_key=meals.delete
```

**Users:**
```bash
rabbitmqadmin declare exchange name=users.exchange type=topic durable=true
rabbitmqadmin declare queue name=users.queue durable=true
rabbitmqadmin declare binding source=users.exchange destination=users.queue routing_key=users.submit
```

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

### Пример Consumer для Users на C#

```csharp
public class UserConsumer
{
    private readonly IConnection _connection;
    private readonly IModel _channel;

    public UserConsumer()
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
        // Consume user messages
        var userConsumer = new EventingBasicConsumer(_channel);
        userConsumer.Received += async (model, ea) =>
        {
            var body = ea.Body.ToArray();
            var message = Encoding.UTF8.GetString(body);
            var user = JsonSerializer.Deserialize<User>(message);
            
            // Process user data
            await AddOrUpdateUserInDatabase(user);
            
            _channel.BasicAck(ea.DeliveryTag, false);
        };
        _channel.BasicConsume(queue: "users.queue", 
                            autoAck: false, 
                            consumer: userConsumer);
    }

    private async Task AddOrUpdateUserInDatabase(User user)
    {
        // Ваша логика добавления или обновления пользователя в БД
    }
}
```

### C# User Class

```csharp
using System;

public class User
{
    public int Id { get; set; }
    public string Email { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public int Age { get; set; }
    public double Height { get; set; }
    public double Weight { get; set; }
    public string Gender { get; set; }
    public string ActivityLevel { get; set; }
    public string Goal { get; set; }
    public bool IsVerified { get; set; }
    public DateTime CreatedAt { get; set; }
    public double CalorieGoal { get; set; }
    public double ProteinGoal { get; set; }
    public double WaterGoal { get; set; }
    public int StepsGoal { get; set; }
}
```

## Тестирование

### cURL примеры

**Отправить данные пользователя:**
```bash
curl -X POST http://localhost:8082/users/submit \
  -H "Content-Type: application/json" \
  -d '{
    "id": 123,
    "email": "user@example.com",
    "firstName": "Alex",
    "lastName": "Ivanov",
    "age": 28,
    "height": 180.0,
    "weight": 75.5,
    "gender": "male",
    "activityLevel": "moderate",
    "goal": "maintain",
    "isVerified": true,
    "createdAt": "2026-02-17T10:15:30.000Z",
    "calorieGoal": 2200.0,
    "proteinGoal": 150.0,
    "waterGoal": 2.5,
    "stepsGoal": 10000
  }'
```

**Добавить прием пищи:**
```bash
curl -X POST http://localhost:8082/meals/add \
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
curl -X DELETE http://localhost:8082/meals/delete \
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
│   └── RabbitMQConfig.java          # Конфигурация RabbitMQ (Exchange, Queue, Binding создаются вручную)
├── controller/
│   ├── MealsController.java         # REST endpoints для meals
│   └── UserController.java          # REST endpoints для users
├── dto/
│   ├── AddMealRequest.java          # DTO для добавления meal
│   ├── DeleteMealRequest.java       # DTO для удаления meal
│   ├── MealResponse.java            # DTO ответа для meal
│   ├── UserRequest.java             # DTO для отправки user
│   └── UserResponse.java            # DTO ответа для user
├── models/
│   ├── Meal.java                    # Модель данных Meal
│   ├── MealType.java                # Enum типов еды
│   └── User.java                    # Модель данных User
└── service/
    ├── MealQueueService.java        # Сервис отправки Meal в RabbitMQ
    └── UserQueueService.java        # Сервис отправки User в RabbitMQ
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
