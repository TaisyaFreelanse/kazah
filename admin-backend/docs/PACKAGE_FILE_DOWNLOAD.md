# Загрузка файлов пакетов

## Обзор

Android приложение может загружать файлы пакетов с сервера вместо использования локальных assets. Это позволяет:
- Использовать новые пакеты без обновления приложения
- Получать обновления файлов автоматически
- Работать офлайн после первой загрузки

## API Endpoint

### GET /api/public/packages/:id/files/:language

**Описание:** Скачивает Excel файл пакета для указанного языка

**Параметры:**
- `id` (URL) - ID пакета
- `language` (URL) - Язык файла (`KZ` или `RU`)

**Требования:**
- Пакет должен быть активен
- Файл должен существовать на сервере

**Ответы:**

**200 OK** - Файл отправлен
- Content-Type: `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- Content-Disposition: attachment с именем файла
- Body: Бинарные данные Excel файла

**400 Bad Request** - Неверный язык
```json
{
  "error": "Неверный язык. Должен быть KZ или RU"
}
```

**404 Not Found** - Пакет не найден или неактивен
```json
{
  "error": "Пакет не найден"
}
```

**404 Not Found** - Файл не найден
```json
{
  "error": "Файл на казахском языке не найден"
}
```

**500 Internal Server Error** - Ошибка сервера
```json
{
  "error": "Ошибка получения файла",
  "details": "..."
}
```

## Использование в Android приложении

### PackageFileService

Сервис для загрузки и кэширования файлов пакетов:

```dart
final packageFileService = PackageFileService();

// Загрузить файл пакета
final filePath = await packageFileService.downloadPackageFile(
  packageId: '1',
  language: 'KZ',
);

if (filePath != null) {
  // Файл загружен и сохранен локально
  // Используйте filePath для парсинга
}
```

### Кэширование

Файлы автоматически кэшируются в:
- Android: `/data/data/com.example.app/files/package_files/`
- iOS: `Documents/package_files/`

**Имя файла:** `package_{packageId}_{language}.xlsx`

### Очистка кэша

```dart
// Очистить кэш для конкретного пакета
await packageFileService.clearCacheForPackage('1');

// Очистить весь кэш
await packageFileService.clearAllCache();
```

## Логика загрузки

### Приоритет загрузки

1. **Проверка кэша** - если файл уже загружен, используется кэш
2. **Загрузка с сервера** - для числовых ID из API
3. **Fallback на assets** - для обратной совместимости

### Пример потока

```
Запрос вопросов из пакета
  ↓
Проверка кэша
  ↓ (если нет в кэше)
Загрузка с сервера
  ↓ (если успешно)
Сохранение в кэш
  ↓
Парсинг файла
  ↓ (если ошибка)
Fallback на assets
```

## Безопасность

- Endpoint публичный (не требует авторизации)
- Проверяется активность пакета
- Проверяется существование файла
- Валидация языка (только KZ или RU)

## Производительность

- Кэширование уменьшает количество запросов
- Файлы загружаются только один раз
- Работает офлайн после первой загрузки
- Автоматическая проверка кэша

## Обработка ошибок

### Ошибки загрузки

```dart
try {
  final filePath = await packageFileService.downloadPackageFile(...);
  if (filePath == null) {
    // Файл не найден или ошибка загрузки
    // Используется fallback на assets
  }
} catch (e) {
  // Ошибка сети или сервера
  // Используется fallback на assets
}
```

### Fallback механизм

Если загрузка с сервера не удалась:
1. Используется локальный файл из assets (если есть)
2. Для старых пакетов (строковые ID) используется старый маппинг
3. Для новых пакетов возвращается пустой список

## Примеры использования

### Загрузка файла пакета

```dart
final packageFileService = PackageFileService();

// Загрузить файл для пакета ID=1 на казахском
final kzFile = await packageFileService.downloadPackageFile(
  packageId: '1',
  language: 'KZ',
);

// Загрузить файл для пакета ID=1 на русском
final ruFile = await packageFileService.downloadPackageFile(
  packageId: '1',
  language: 'RU',
);
```

### Проверка кэша

```dart
final isCached = await packageFileService.isFileCached('1', 'KZ');
if (isCached) {
  // Файл уже в кэше
}
```

### Использование в QuestionService

```dart
// Автоматически используется в _loadPackageQuestions()
final questions = await questionService.getQuestions(
  language: 'KZ',
  purchasedPackageIds: ['1', '2'],
);
// Файлы загружаются автоматически с сервера или из кэша
```

## Тестирование

### Тест endpoint

```bash
# Загрузить файл пакета ID=1 на казахском
curl -O https://blim-bilem-admin-backend.onrender.com/api/public/packages/1/files/KZ

# Загрузить файл пакета ID=1 на русском
curl -O https://blim-bilem-admin-backend.onrender.com/api/public/packages/1/files/RU
```

### Тест в приложении

1. Создать новый пакет в админ-панели
2. Загрузить файлы для пакета
3. Проверить, что файлы доступны через API
4. Проверить загрузку в приложении
5. Проверить кэширование

## Важные замечания

1. **Размер файлов** - рекомендуется до 10MB
2. **Формат** - только Excel (.xlsx, .xls)
3. **Кэш** - файлы хранятся локально до очистки
4. **Обновления** - для получения обновлений нужно очистить кэш
5. **Офлайн** - работает после первой загрузки

