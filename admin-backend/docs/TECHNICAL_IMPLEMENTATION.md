# Техническая реализация админ-панели

## Обзор

Админ-панель "Blim Bilem" реализована с использованием современного стека технологий для обеспечения надежности, безопасности и удобства использования.

## Backend API

### Технологии

- **Node.js** - серверная платформа
- **Express.js** - веб-фреймворк
- **PostgreSQL** - реляционная база данных
- **JWT** - аутентификация и авторизация
- **Multer** - обработка загрузки файлов

### Архитектура

```
admin-backend/
├── server.js          # Главный файл сервера
├── db/
│   └── database.js   # Подключение к PostgreSQL
├── models/           # Модели данных
├── routes/           # API маршруты
├── middleware/       # Middleware (auth, error handling)
└── uploads/          # Хранилище загруженных файлов
```

### API Endpoints

#### Аутентификация
- `POST /api/auth/login` - Вход в систему
- `POST /api/auth/init` - Инициализация первого администратора

#### Пакеты (требует авторизации)
- `GET /api/packages` - Получить все пакеты
- `GET /api/packages/:id` - Получить один пакет
- `POST /api/packages` - Создать пакет
- `PUT /api/packages/:id` - Обновить пакет
- `DELETE /api/packages/:id` - Удалить пакет
- `POST /api/packages/:id/upload` - Загрузить файл пакета
- `DELETE /api/packages/:id/file/:language` - Удалить файл пакета

#### Публичный API (для приложения)
- `GET /api/public/packages` - Получить активные пакеты
- `GET /api/public/packages/:id` - Получить активный пакет по ID

## Хранение файлов Excel

### Структура хранения

```
uploads/
├── packages/
│   ├── package_1_KZ_1234567890.xlsx
│   └── package_1_RU_1234567890.xlsx
├── public-questions/
│   ├── questions_kz.xlsx
│   └── questions_ru.xlsx
└── phrases/
    ├── phrases_kz.xlsx
    └── phrases_ru.xlsx
```

### Конфигурация Multer

```javascript
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../uploads/packages');
    await fs.mkdir(uploadDir, { recursive: true });
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const packageId = req.params.id;
    const language = req.body.language || 'KZ';
    const ext = path.extname(file.originalname);
    const filename = `package_${packageId}_${language}_${Date.now()}${ext}`;
    cb(null, filename);
  },
});
```

### Ограничения

- Максимальный размер файла: **10MB**
- Разрешенные форматы: `.xlsx`, `.xls`
- Валидация MIME типа на сервере

## Синхронизация данных с приложением

### Публичный API

Приложение получает данные через публичный endpoint `/api/public/packages`, который:
- Не требует авторизации
- Возвращает только активные пакеты
- Форматирует данные для использования в приложении

### Формат ответа

```json
[
  {
    "id": 1,
    "name": "Больше вопросов",
    "nameKZ": "Көбірек сұрақтар",
    "nameRU": "Больше вопросов",
    "iconColor": "#9C27B0",
    "price": 1000,
    "isActive": true,
    "hasFiles": {
      "kz": true,
      "ru": true
    }
  }
]
```

### Кэширование

Приложение использует кэширование пакетов (5 минут) для оптимизации производительности.

## Система авторизации

### JWT (JSON Web Tokens)

- **Алгоритм**: HS256
- **Секретный ключ**: хранится в переменной окружения `JWT_SECRET`
- **Срок действия**: неограничен (можно добавить expiration)

### Middleware аутентификации

```javascript
export const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Токен доступа не предоставлен' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Недействительный токен' });
    }
    req.user = user;
    next();
  });
};
```

### Хранение токена

Токен хранится в `localStorage` на клиенте и отправляется в заголовке `Authorization: Bearer <token>`.

## Валидация загружаемых Excel файлов

### На клиенте (Frontend)

```javascript
const validExtensions = ['.xlsx', '.xls'];
const fileExtension = file.name.toLowerCase().substring(file.name.lastIndexOf('.'));
if (!validExtensions.includes(fileExtension)) {
  setError('Разрешены только Excel файлы (.xlsx, .xls)');
  return;
}
```

### На сервере (Backend)

```javascript
fileFilter: (req, file, cb) => {
  if (file.mimetype === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ||
      file.mimetype === 'application/vnd.ms-excel') {
    cb(null, true);
  } else {
    cb(new Error('Разрешены только Excel файлы (.xlsx, .xls)'));
  }
}
```

### Проверки

1. **Расширение файла** - проверка на клиенте
2. **MIME тип** - проверка на сервере
3. **Размер файла** - ограничение 10MB

## Обработка ошибок загрузки

### Структура обработки

```javascript
try {
  // Загрузка файла
  const response = await axios.post(`/api/packages/${id}/upload`, formData);
  setSuccess('Файл успешно загружен');
} catch (err) {
  // Обработка ошибок
  if (err.response) {
    // Ошибка от сервера
    setError(err.response.data.error || 'Ошибка загрузки файла');
  } else if (err.request) {
    // Ошибка сети
    setError('Ошибка соединения с сервером');
  } else {
    // Другая ошибка
    setError('Произошла ошибка');
  }
} finally {
  // Очистка состояния
  setUploading({ ...uploading, [language]: false });
}
```

### Типы ошибок

- **400** - Неверный формат файла
- **401** - Не авторизован
- **404** - Пакет не найден
- **413** - Файл слишком большой
- **500** - Ошибка сервера

## UI компоненты

### File Picker для загрузки Excel

```jsx
<label className="upload-button">
  <input
    type="file"
    accept=".xlsx,.xls"
    onChange={(e) => handleFileUpload('KZ', e.target.files[0])}
    disabled={uploading.KZ}
    style={{ display: 'none' }}
  />
  {uploading.KZ ? 'Загрузка...' : 'Загрузить Excel'}
</label>
```

**Особенности:**
- Скрытый input с кастомной кнопкой
- Валидация формата на клиенте
- Индикатор загрузки
- Обработка ошибок

### Color Picker для выбора цвета значка

```jsx
<div className="color-picker-container">
  <div
    className="color-preview"
    style={{ backgroundColor: iconColor }}
    onClick={() => setShowColorPicker(!showColorPicker)}
  />
  <input
    type="color"
    value={iconColor}
    onChange={(e) => setIconColor(e.target.value)}
    className="color-input"
  />
  <input
    type="text"
    value={iconColor}
    onChange={(e) => setIconColor(e.target.value)}
    className="color-text-input"
    placeholder="#4CAF50"
  />
</div>
```

**Особенности:**
- Визуальный превью цвета
- Нативный color picker
- Текстовый ввод HEX кода
- Синхронизация между компонентами

### Toggle Switch для активации/деактивации

```jsx
<label className="toggle-container">
  <input
    type="checkbox"
    checked={isActive}
    onChange={handleToggleActive}
    className="toggle-input"
  />
  <span className="toggle-slider"></span>
  <span className="toggle-text">{isActive ? 'Активен' : 'Неактивен'}</span>
</label>
```

**Особенности:**
- Кастомный стиль checkbox
- Плавная анимация
- Визуальная обратная связь

### Диалоги подтверждения удаления

```javascript
const confirmMessage = `Вы уверены, что хотите удалить пакет "${packageName}"?\n\n` +
  `⚠️ ВНИМАНИЕ: Это действие нельзя отменить!\n` +
  `- Пакет полностью исчезнет из админ-панели\n` +
  `- Все файлы пакета будут удалены\n` +
  `- Пакет не будет использоваться в игре\n` +
  `- Пользователи, которые купили пакет, потеряют доступ к вопросам\n\n` +
  `Если вы хотите временно скрыть пакет, используйте тумблер "Активен/Неактивен" вместо удаления.`;

if (!window.confirm(confirmMessage)) {
  return;
}
```

**Особенности:**
- Детальное описание последствий
- Рекомендации по альтернативным действиям
- Предупреждение о необратимости

### Формы редактирования пакетов

```jsx
{isEditing ? (
  <div className="package-details">
    <div className="detail-row">
      <label>Название (KZ):</label>
      <input
        type="text"
        value={nameKZ}
        onChange={(e) => setNameKZ(e.target.value)}
        className="detail-input"
      />
    </div>
    {/* ... другие поля ... */}
    <button onClick={handleSave}>Сохранить</button>
    <button onClick={handleCancel}>Отмена</button>
  </div>
) : (
  <button onClick={() => setEditingPackage(pkg.id)}>Редактировать</button>
)}
```

**Особенности:**
- Inline редактирование
- Валидация на клиенте
- Автоматическое сохранение при создании
- Отмена изменений

## База данных

### PostgreSQL

#### Таблица packages

```sql
CREATE TABLE packages (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  name_kz VARCHAR(255),
  name_ru VARCHAR(255),
  icon_color VARCHAR(7) DEFAULT '#4CAF50',
  price INTEGER NOT NULL DEFAULT 1000,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Таблица package_files

```sql
CREATE TABLE package_files (
  id SERIAL PRIMARY KEY,
  package_id INTEGER REFERENCES packages(id) ON DELETE CASCADE,
  language VARCHAR(2) NOT NULL CHECK (language IN ('KZ', 'RU')),
  file_url VARCHAR(500),
  file_name VARCHAR(255),
  file_size BIGINT,
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(package_id, language)
);
```

### Связи

- `package_files.package_id` → `packages.id` (ON DELETE CASCADE)
- При удалении пакета файлы удаляются автоматически

## Безопасность

### Меры безопасности

1. **JWT токены** - защита API endpoints
2. **Валидация файлов** - проверка MIME типа и размера
3. **Ограничение размера** - максимум 10MB
4. **Очистка старых файлов** - автоматическое удаление при замене
5. **Обработка ошибок** - безопасные сообщения об ошибках

### Переменные окружения

```env
PORT=3000
NODE_ENV=production
JWT_SECRET=your-secret-key
DATABASE_URL=postgresql://user:password@host:port/database
ADMIN_DEFAULT_PASSWORD=default-password
UPLOAD_DIR=./uploads
```

## Развертывание

### Render.com

- **Backend**: Node.js Web Service
- **Database**: PostgreSQL (Render Managed)
- **Frontend**: Static Site (Vite build)

### Конфигурация

- Автоматическое развертывание из Git
- Переменные окружения через Render Dashboard
- Health check endpoint: `/api/health`

## Производительность

### Оптимизации

1. **Кэширование пакетов** в приложении (5 минут)
2. **Индексы базы данных** на часто используемых полях
3. **Статическая раздача файлов** через Express
4. **Ограничение размера файлов** для быстрой загрузки

## Мониторинг

### Логирование

- Ошибки загрузки файлов
- Ошибки подключения к базе данных
- Неудачные попытки авторизации

### Health Check

```javascript
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Blim Bilem Admin API is running' });
});
```

