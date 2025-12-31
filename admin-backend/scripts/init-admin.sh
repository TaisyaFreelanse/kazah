#!/bin/bash

# Скрипт для инициализации администратора
# Использование: ./init-admin.sh

API_URL="${API_URL:-https://blim-bilem-admin-backend.onrender.com}"

echo "🔐 Инициализация администратора..."
echo "API URL: $API_URL"
echo ""

response=$(curl -s -X POST "$API_URL/api/auth/init" \
  -H "Content-Type: application/json")

echo "Ответ сервера:"
echo "$response" | jq '.' 2>/dev/null || echo "$response"
echo ""

if echo "$response" | grep -q "успешно\|success"; then
  echo "✅ Администратор успешно создан!"
  echo ""
  echo "Учетные данные:"
  echo "  Username: admin"
  echo "  Password: значение из ADMIN_DEFAULT_PASSWORD (по умолчанию: admin123)"
  echo ""
  echo "Теперь вы можете войти в админ-панель:"
  echo "  Frontend: https://blim-bilem-admin-frontend.onrender.com"
else
  echo "❌ Ошибка инициализации"
  echo "Возможно, администратор уже создан ранее"
fi

