# Команды для настройки и проверки

## ✅ Проверка статуса

### 1. Проверить здоровье API
```bash
curl https://blim-bilem-admin-backend.onrender.com/api/health
```

### 2. Инициализировать администратора
```bash
curl -X POST https://blim-bilem-admin-backend.onrender.com/api/auth/init \
  -H "Content-Type: application/json"
```

### 3. Проверить вход (после инициализации)
```bash
curl -X POST https://blim-bilem-admin-backend.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

## 📋 Полный скрипт проверки

Скопируйте и выполните в терминале:

```bash
#!/bin/bash

API_URL="https://blim-bilem-admin-backend.onrender.com"

echo "🔍 Проверка API..."
echo ""

# 1. Health check
echo "1️⃣ Health Check:"
curl -s "$API_URL/api/health" | jq '.' || curl -s "$API_URL/api/health"
echo ""
echo ""

# 2. Инициализация администратора
echo "2️⃣ Инициализация администратора:"
response=$(curl -s -X POST "$API_URL/api/auth/init" \
  -H "Content-Type: application/json")
echo "$response" | jq '.' || echo "$response"
echo ""
echo ""

# 3. Тест входа
echo "3️⃣ Тест входа:"
login_response=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
echo "$login_response" | jq '.' || echo "$login_response"
echo ""

if echo "$login_response" | grep -q "token"; then
  echo "✅ Всё работает правильно!"
else
  echo "⚠️ Проверьте логи или попробуйте снова"
fi
```

## 🚀 Быстрые команды

### Инициализация администратора (одна команда)
```bash
curl -X POST https://blim-bilem-admin-backend.onrender.com/api/auth/init -H "Content-Type: application/json"
```

### Проверка работы API
```bash
curl https://blim-bilem-admin-backend.onrender.com/api/health
```

### Вход в систему
```bash
curl -X POST https://blim-bilem-admin-backend.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

## 📊 Статус сервисов

- **Backend:** https://blim-bilem-admin-backend.onrender.com ✅ Live
- **Frontend:** https://blim-bilem-admin-frontend.onrender.com ✅ Live
- **PostgreSQL:** blim-bilem-db ✅ Available

## 🔗 Ссылки

- Backend Dashboard: https://dashboard.render.com/web/srv-d5agh1ogjchc73b9n1e0
- Frontend Dashboard: https://dashboard.render.com/static/srv-d5agh63e5dus73f3sca0
- PostgreSQL Dashboard: https://dashboard.render.com/d/dpg-d5agklre5dus73f3ui10-a

