#!/bin/bash

# Скрипт для тестирования входа
# Использование: ./test-login.sh [username] [password]

API_URL="${API_URL:-https://blim-bilem-admin-backend.onrender.com}"
USERNAME="${1:-admin}"
PASSWORD="${2:-admin123}"

echo "🔑 Тестирование входа..."
echo "API URL: $API_URL"
echo "Username: $USERNAME"
echo ""

response=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}")

echo "Ответ сервера:"
echo "$response" | jq '.' 2>/dev/null || echo "$response"
echo ""

if echo "$response" | grep -q "token"; then
  echo "✅ Вход успешен!"
  token=$(echo "$response" | jq -r '.token' 2>/dev/null)
  if [ -n "$token" ] && [ "$token" != "null" ]; then
    echo ""
    echo "Токен получен (первые 20 символов): ${token:0:20}..."
  fi
else
  echo "❌ Ошибка входа"
  echo "Проверьте правильность username и password"
fi

