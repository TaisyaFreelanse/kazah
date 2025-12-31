# Инструкция по настройке и деплою админ-панели

## Этап 12.1: Общая структура админ-панели ✅

Создана базовая структура админ-панели с бекендом и фронтендом.

## Структура проекта

```
kazah/
├── admin-backend/          # Backend API (Node.js/Express)
│   ├── models/            # MongoDB модели
│   ├── routes/            # API маршруты
│   ├── middleware/        # Middleware (авторизация)
│   └── server.js          # Главный файл сервера
│
└── admin-frontend/         # Frontend (React + Vite)
    └── src/
        ├── pages/         # Страницы приложения
        ├── components/    # React компоненты
        └── context/       # Context API (авторизация)
```

## Локальная установка и запуск

### 1. Backend

```bash
cd admin-backend
npm install
cp .env.example .env
# Отредактируйте .env файл
npm run dev
```

**Важно:** При первом запуске выполните инициализацию администратора:
```bash
POST http://localhost:3000/api/auth/init
```

Или используйте curl:
```bash
curl -X POST http://localhost:3000/api/auth/init
```

По умолчанию создается администратор:
- Username: `admin`
- Password: значение из `ADMIN_DEFAULT_PASSWORD` в `.env` (по умолчанию `admin123`)

### 2. Frontend

```bash
cd admin-frontend
npm install
cp .env.example .env
# Отредактируйте .env, укажите VITE_API_URL=http://localhost:3000
npm run dev
```

Откройте браузер: http://localhost:5173

## Деплой на Render

### Backend (Web Service)

1. **Создайте MongoDB базу данных:**
   - В Render Dashboard создайте новый MongoDB
   - Или используйте MongoDB Atlas (бесплатный tier)

2. **Создайте Web Service:**
   - Repository: подключите ваш репозиторий
   - Root Directory: `admin-backend`
   - Environment: `Node`
   - Build Command: `npm install`
   - Start Command: `npm start`

3. **Настройте Environment Variables:**
   ```
   NODE_ENV=production
   PORT=10000
   JWT_SECRET=<сгенерируйте случайную строку>
   MONGODB_URI=<URI вашей MongoDB базы>
   ADMIN_DEFAULT_PASSWORD=<безопасный пароль>
   ```

4. **После деплоя инициализируйте администратора:**
   ```bash
   POST https://your-backend-url.onrender.com/api/auth/init
   ```

### Frontend (Static Site)

1. **Создайте Static Site:**
   - Repository: подключите ваш репозиторий
   - Root Directory: `admin-frontend`
   - Build Command: `npm install && npm run build`
   - Publish Directory: `dist`

2. **Настройте Environment Variables:**
   ```
   VITE_API_URL=https://your-backend-url.onrender.com
   ```

3. **После деплоя обновите переменную окружения:**
   - В Render Dashboard для Static Site добавьте переменную `VITE_API_URL`
   - Пересоберите сайт

## Функциональность (Этап 12.1)

✅ **Реализовано:**

1. **Система авторизации:**
   - Вход в систему (JWT токены)
   - Проверка токена
   - Смена пароля администратора
   - Защищенные маршруты

2. **Главный экран:**
   - Три раздела: Общедоступные, Пакетные, ФинФразы
   - Навигация между разделами
   - Выход из системы

3. **Backend API:**
   - RESTful API для всех операций
   - Загрузка и хранение Excel файлов
   - MongoDB для хранения данных
   - Статическая раздача файлов

## Следующие этапы

- [ ] Раздел "Общедоступные" - загрузка Excel файлов
- [ ] Раздел "Пакетные" - управление пакетами
- [ ] Раздел "ФинФразы" - загрузка фраз
- [ ] Синхронизация с Android приложением

## Тестирование

1. Запустите backend и frontend локально
2. Откройте http://localhost:5173
3. Войдите с учетными данными администратора
4. Проверьте навигацию между разделами

## Примечания

- MongoDB обязательна для работы backend
- Файлы загружаются в папку `uploads/` на сервере
- JWT токены действительны 24 часа
- Пароли хешируются с помощью bcrypt

