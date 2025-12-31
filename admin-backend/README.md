# Blim Bilem Admin Backend

Backend API для админ-панели приложения Blim Bilem.

## Установка

```bash
npm install
```

## Настройка

1. Скопируйте `.env.example` в `.env`:
```bash
cp .env.example .env
```

2. Отредактируйте `.env` и укажите:
   - `JWT_SECRET` - секретный ключ для JWT токенов
   - `MONGODB_URI` - URI подключения к MongoDB
   - `ADMIN_DEFAULT_PASSWORD` - пароль администратора по умолчанию

## Запуск

### Development
```bash
npm run dev
```

### Production
```bash
npm start
```

## Инициализация

При первом запуске создайте администратора:
```bash
POST /api/auth/init
```

## API Endpoints

### Авторизация
- `POST /api/auth/init` - Инициализация администратора
- `POST /api/auth/login` - Вход в систему
- `GET /api/auth/verify` - Проверка токена
- `POST /api/auth/change-password` - Смена пароля

### Общедоступные вопросы
- `GET /api/public-questions` - Получить список файлов
- `POST /api/public-questions/upload` - Загрузить Excel файл
- `DELETE /api/public-questions/:id` - Удалить файл

### Пакеты
- `GET /api/packages` - Получить все пакеты
- `GET /api/packages/:id` - Получить один пакет
- `POST /api/packages` - Создать новый пакет
- `PUT /api/packages/:id` - Обновить пакет
- `DELETE /api/packages/:id` - Удалить пакет
- `POST /api/packages/:id/upload` - Загрузить файл для пакета
- `DELETE /api/packages/:id/file/:language` - Удалить файл пакета

### Фразы
- `GET /api/phrases` - Получить список файлов
- `POST /api/phrases/upload` - Загрузить Excel файл
- `DELETE /api/phrases/:id` - Удалить файл

## Деплой на Render

1. Создайте новый Web Service на Render
2. Подключите MongoDB (можно использовать MongoDB Atlas)
3. Установите переменные окружения в Render Dashboard
4. Укажите Build Command: `npm install`
5. Укажите Start Command: `npm start`

