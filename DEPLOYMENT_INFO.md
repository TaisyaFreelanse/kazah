# Информация о деплое на Render

## ✅ Сервисы созданы

### Backend API
- **Название:** blim-bilem-admin-backend
- **URL:** https://blim-bilem-admin-backend.onrender.com
- **Тип:** Web Service (Node.js)
- **Статус:** Деплой в процессе
- **Dashboard:** https://dashboard.render.com/web/srv-d5agh1ogjchc73b9n1e0

### Frontend
- **Название:** blim-bilem-admin-frontend
- **URL:** https://blim-bilem-admin-frontend.onrender.com
- **Тип:** Static Site
- **Статус:** Деплой в процессе
- **Dashboard:** https://dashboard.render.com/static/srv-d5agh63e5dus73f3sca0

## ⚙️ Настройка переменных окружения

### Backend (через Dashboard Render)

1. Перейдите в Dashboard бекенда: https://dashboard.render.com/web/srv-d5agh1ogjchc73b9n1e0/settings
2. В разделе "Environment" добавьте/обновите переменные:

```
NODE_ENV=production
PORT=10000
JWT_SECRET=blim-bilem-secret-key-2024-change-in-production
DATABASE_URL=postgresql://blim_bilem_db_user:password@dpg-d5agklre5dus73f3ui10-a.oregon-postgres.render.com:5432/blim_bilem_db
POSTGRES_URL=postgresql://blim_bilem_db_user:password@dpg-d5agklre5dus73f3ui10-a.oregon-postgres.render.com:5432/blim_bilem_db
ADMIN_DEFAULT_PASSWORD=admin123
```

**Важно:** 
- Получите правильный connection string из Dashboard PostgreSQL базы данных: https://dashboard.render.com/d/dpg-d5agklre5d3ui10-a
- Замените `password` на реальный пароль из connection string

### Frontend (через Dashboard Render)

1. Перейдите в Dashboard фронтенда: https://dashboard.render.com/static/srv-d5agh63e5dus73f3sca0/settings
2. В разделе "Environment" добавьте переменную:

```
VITE_API_URL=https://blim-bilem-admin-backend.onrender.com
```

3. После добавления переменной пересоберите сайт (Manual Deploy)

## 🗄️ База данных PostgreSQL

✅ **База данных создана:** `blim-bilem-db`
- **ID:** dpg-d5agklre5dus73f3ui10-a
- **Dashboard:** https://dashboard.render.com/d/dpg-d5agklre5dus73f3ui10-a
- **Имя базы:** blim_bilem_db
- **Пользователь:** blim_bilem_db_user

### Получение Connection String

1. Перейдите в Dashboard базы данных: https://dashboard.render.com/d/dpg-d5agklre5dus73f3ui10-a
2. Найдите раздел "Connections" или "Connection String"
3. Скопируйте connection string (формат: `postgresql://user:password@host:port/database`)
4. Обновите переменные `DATABASE_URL` и `POSTGRES_URL` в настройках бекенда

**Примечание:** Таблицы создаются автоматически при первом запуске бекенда.

## 🚀 Инициализация администратора

После успешного деплоя бекенда:

1. Откройте: https://blim-bilem-admin-backend.onrender.com/api/auth/init
2. Или используйте curl:
```bash
curl -X POST https://blim-bilem-admin-backend.onrender.com/api/auth/init
```

Это создаст администратора:
- **Username:** admin
- **Password:** значение из `ADMIN_DEFAULT_PASSWORD` (по умолчанию: admin123)

## 📝 Проверка статуса деплоя

Проверить статус деплоя можно через:
- Dashboard бекенда: https://dashboard.render.com/web/srv-d5agh1ogjchc73b9n1e0
- Dashboard фронтенда: https://dashboard.render.com/static/srv-d5agh63e5dus73f3sca0

## 🔗 Ссылки

- **Backend API:** https://blim-bilem-admin-backend.onrender.com
- **Frontend:** https://blim-bilem-admin-frontend.onrender.com
- **Health Check:** https://blim-bilem-admin-backend.onrender.com/api/health

## ⚠️ Важные замечания

1. **MongoDB URI:** Обязательно настройте правильный MongoDB URI перед использованием
2. **JWT_SECRET:** Измените на более безопасный ключ в production
3. **ADMIN_DEFAULT_PASSWORD:** Измените пароль администратора после первого входа
4. **CORS:** Бекенд настроен на работу с фронтендом, но может потребоваться дополнительная настройка CORS

## 🔄 Автоматический деплой

Оба сервиса настроены на автоматический деплой при push в ветку `main` репозитория:
- https://github.com/TaisyaFreelanse/kazah.git

