# Blim Bilem - Мобильная викторина

Мобильное приложение-викторина на Flutter с поддержкой казахского и русского языков.

## Структура проекта

```
blim_bilem/
├── lib/
│   ├── main.dart                    # Точка входа приложения
│   ├── app.dart                     # Основной виджет приложения
│   ├── screens/                     # Экраны приложения
│   ├── widgets/                     # Переиспользуемые виджеты
│   ├── models/                      # Модели данных
│   ├── services/                    # Бизнес-логика и сервисы
│   ├── providers/                   # State management (Provider)
│   └── constants/                   # Константы (цвета, строки)
├── assets/
│   ├── data/                        # Excel файлы с вопросами
│   └── images/                      # Изображения
└── pubspec.yaml                     # Конфигурация проекта
```

## Установка зависимостей

```bash
flutter pub get
```

## Запуск проекта

```bash
flutter run
```

## Основные компоненты

### Screens
- `MainMenuScreen` - Главное меню
- `GameScreen` - Экран игры
- `PackagesScreen` - Экран дополнительных пакетов
- `ResultScreen` - Экран победы
- `TimeoutScreen` - Экран истечения времени

### Services
- `QuestionService` - Управление вопросами
- `LanguageService` - Управление языками (KZ/RU)
- `TimerService` - Таймер для вопросов
- `ExcelParser` - Парсинг Excel файлов
- `PurchaseService` - Управление покупками

### Models
- `Question` - Модель вопроса
- `PackageInfo` - Информация о пакетах вопросов

## Следующие шаги

1. Скопировать Excel файлы в `assets/data/`
2. Реализовать парсер Excel
3. Реализовать логику игры
4. Создать UI экранов
5. Интегрировать In-App Purchase

