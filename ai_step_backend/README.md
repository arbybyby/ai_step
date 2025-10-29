# AI Step Backend

Spring Boot приложение для отслеживания шагов с использованием PostgreSQL.

## Технологии

- Java 21
- Spring Boot 3.5.6
- PostgreSQL
- Spring Data JPA
- Spring Security
- JWT Authentication
- Docker & Docker Compose

## Настройка базы данных

### Вариант 1: Использование Docker Compose (рекомендуется)

1. Скопируйте файл с примером переменных окружения:
```bash
cp .env.example .env
```

2. При необходимости отредактируйте `.env` файл с вашими настройками

3. Запустите базу данных и приложение:
```bash
docker-compose up -d
```

База данных будет автоматически инициализирована с помощью `init.sql`.

### Вариант 2: Локальная PostgreSQL

1. Установите PostgreSQL

2. Создайте базу данных:
```sql
CREATE DATABASE ai_step_db;
```

3. Выполните SQL скрипт для создания таблиц:
```bash
psql -U postgres -d ai_step_db -f init.sql
```

4. Обновите `src/main/resources/application.properties`:
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/ai_step_db
spring.datasource.username=postgres
spring.datasource.password=your_password
```

## Запуск приложения

### С Docker Compose
```bash
docker-compose up
```

### Локально
```bash
./mvnw spring-boot:run
```

Приложение будет доступно по адресу: http://localhost:8080

## Структура базы данных

### Таблицы:
- `users` - информация о пользователях
- `steps` - агрегированные данные о шагах
- `step_data` - детальные данные акселерометра

### Представления:
- `daily_step_totals` - дневная статистика шагов

## API Endpoints

- `POST /api/auth/register` - Регистрация пользователя
- `POST /api/auth/login` - Вход в систему
- `POST /api/steps/submit` - Отправка данных о шагах
- `GET /api/steps/daily?date={date}` - Получение дневной статистики
- `GET /api/steps/history?from={date}&to={date}` - История шагов

## Разработка

### Требования
- Java 21
- Maven 3.6+
- Docker & Docker Compose (опционально)

### Сборка проекта
```bash
./mvnw clean install
```

### Запуск тестов
```bash
./mvnw test
```

## Конфигурация

Основные настройки находятся в `application.properties`:
- Подключение к базе данных
- JPA/Hibernate настройки
- JWT секрет и время жизни токена
- Уровни логирования

## Docker

### Сборка образа
```bash
docker build -t ai_step_backend .
```

### Запуск контейнера
```bash
docker run -p 8080:8080 --env-file .env ai_step_backend
```

## Миграции базы данных

Приложение использует `spring.jpa.hibernate.ddl-auto=update` для автоматического обновления схемы БД.
Для продакшена рекомендуется использовать инструменты миграций, такие как Flyway или Liquibase.

## Переменные окружения

| Переменная | Описание | Значение по умолчанию |
|------------|----------|----------------------|
| POSTGRES_DB | Имя базы данных | ai_step_db |
| POSTGRES_USER | Пользователь БД | postgres |
| POSTGRES_PASSWORD | Пароль БД | postgres |
| POSTGRES_PORT | Порт БД | 5432 |
| DB_HOST | Хост БД | localhost |

## Лицензия

MIT
