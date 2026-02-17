# Error Handling в приложении

## Обзор

В приложении реализована система обработки ошибок, которая предоставляет пользователю понятные сообщения об ошибках вместо технических деталей.

## Компоненты

### 1. `MealsServiceException`

Кастомный класс исключений для ошибок API:

```dart
class MealsServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;
  
  String get userFriendlyMessage; // Понятное пользователю сообщение
}
```

### 2. `ErrorHandler` (utils/error_handler.dart)

Утилиты для отображения ошибок в UI.

## Примеры использования

### Пример 1: Добавление нового блюда с обработкой ошибок

```dart
import '../services/meals_service.dart';
import '../utils/error_handler.dart';

// В вашем виджете
Future<void> addCustomMeal(BuildContext context) async {
  try {
    final mealsService = MealsService();
    final newMeal = await mealsService.addMeal(
      mealName: 'Овсяная каша',
      mealType: MealType.breakfast,
      grammes: 200.0,
      calories: 350.5,
      protein: 12.5,
      carbs: 58.2,
      fat: 6.8,
    );
    
    // Успешно создано
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Meal "${newMeal.mealName}" added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  } on MealsServiceException catch (e) {
    // Показываем понятное сообщение об ошибке
    ErrorHandler.showError(context, e);
  } catch (e) {
    // Обработка неожиданных ошибок
    ErrorHandler.showError(context, e);
  }
}
```

### Пример 2: Использование ErrorHandler с диалогом

```dart
try {
  final meals = await mealsService.getAllMeals();
  // Обработка данных
} on MealsServiceException catch (e) {
  ErrorHandler.showErrorDialog(
    context,
    e,
    title: 'Failed to load meals',
    onRetry: () {
      // Повторить запрос
      ref.read(allMealsProvider.notifier).fetchAllMeals();
    },
  );
}
```

### Пример 3: Простое отображение ошибки в SnackBar

```dart
try {
  await someApiCall();
} catch (e) {
  ErrorHandler.showError(context, e);
}
```

### Пример 4: Получение только текста сообщения

```dart
try {
  await someApiCall();
} catch (e) {
  final errorMessage = ErrorHandler.getErrorMessage(e);
  print('Error occurred: $errorMessage');
}
```

## Типы ошибок и их сообщения

| HTTP Status | Сообщение пользователю |
|-------------|------------------------|
| 400 | Invalid data. Please check your input. |
| 401 | Authentication failed. Please log in again. |
| 403 | Access denied. You don't have permission to perform this action. |
| 404 | Resource not found. Please check your connection. |
| 500+ | Server error. Please try again later. |
| Network Error | Network error. Please check your internet connection. |
| Timeout | Request timed out. Please try again. |

## Использование в Provider

В провайдерах Riverpod используйте отдельную обработку для `MealsServiceException`:

```dart
Future<void> fetchData() async {
  state = const AsyncValue.loading();
  try {
    final data = await _service.getData();
    state = AsyncValue.data(data);
  } on MealsServiceException catch (e) {
    // Логирование с пользовательским сообщением
    print('Error: ${e.userFriendlyMessage}');
    state = AsyncValue.error(e, StackTrace.current);
  } catch (e) {
    state = AsyncValue.error(e, StackTrace.current);
  }
}
```

## Использование в UI с AsyncValue

```dart
ref.watch(someProvider).when(
  data: (data) => /* Показать данные */,
  loading: () => CircularProgressIndicator(),
  error: (err, stack) {
    String errorMessage = 'An error occurred';
    if (err is MealsServiceException) {
      errorMessage = err.userFriendlyMessage;
    }
    return Column(
      children: [
        Icon(Icons.error_outline, color: Colors.red),
        Text(errorMessage),
        ElevatedButton(
          onPressed: () => ref.refresh(someProvider),
          child: Text('Retry'),
        ),
      ],
    );
  },
);
```

## Best Practices

1. **Всегда ловите `MealsServiceException` отдельно** от общих исключений
2. **Используйте `ErrorHandler`** для единообразного отображения ошибок
3. **Показывайте кнопку "Retry"** где это уместно
4. **Логируйте технические детали** в консоль для отладки
5. **Показывайте пользователю** только `userFriendlyMessage`

## Добавление новых типов ошибок

Чтобы добавить новую категорию ошибок, обновите метод `userFriendlyMessage` в классе `MealsServiceException`:

```dart
String get userFriendlyMessage {
  if (statusCode == 409) {
    return 'This item already exists.';
  }
  // ... остальные проверки
}
```
