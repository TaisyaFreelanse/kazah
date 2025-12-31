#!/bin/bash

# Скрипт для проверки здоровья API
# Использование: ./check-health.sh

API_URL="${API_URL:-https://blim-bilem-admin-backend.onrender.com}"

echo "🏥 Проверка здоровья API..."
echo "API URL: $API_URL"
echo ""

# Проверка health endpoint
health_response=$(curl -s "$API_URL/api/health")
echo "Health Check:"
echo "$health_response" | jq '.' 2>/dev/null || echo "$health_response"
echo ""

# Проверка доступности
if curl -s -f "$API_URL/api/health" > /dev/null; then
  echo "✅ API доступен и работает"
else
  echo "❌ API недоступен"
  exit 1
fi

