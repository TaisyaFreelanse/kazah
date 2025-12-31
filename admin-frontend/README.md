# Blim Bilem Admin Frontend

Frontend для админ-панели приложения Blim Bilem на React.

## Установка

```bash
npm install
```

## Запуск

### Development
```bash
npm run dev
```

Приложение будет доступно по адресу: http://localhost:5173

### Production Build
```bash
npm run build
```

## Деплой на Render

1. Создайте новый Static Site на Render
2. Подключите репозиторий
3. Укажите Build Command: `npm install && npm run build`
4. Укажите Publish Path: `dist`

## Структура

- `/login` - Страница входа
- `/` - Главная панель с разделами
- `/public-questions` - Управление общедоступными вопросами
- `/packages` - Управление пакетами
- `/phrases` - Управление фразами

