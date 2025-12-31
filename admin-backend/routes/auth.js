import express from 'express';
import jwt from 'jsonwebtoken';
import { Admin } from '../models/Admin.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// Инициализация админа по умолчанию (только при первом запуске)
router.post('/init', async (req, res) => {
  try {
    const adminCount = await Admin.count();
    
    if (adminCount > 0) {
      return res.status(400).json({ error: 'Администратор уже инициализирован' });
    }

    const defaultPassword = process.env.ADMIN_DEFAULT_PASSWORD || 'admin123';
    const admin = await Admin.create('admin', defaultPassword);

    res.json({ message: 'Администратор создан успешно', username: 'admin' });
  } catch (error) {
    res.status(500).json({ error: 'Ошибка инициализации администратора', details: error.message });
  }
});

// Вход в систему
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Имя пользователя и пароль обязательны' });
    }

    const admin = await Admin.findByUsername(username);
    if (!admin) {
      return res.status(401).json({ error: 'Неверное имя пользователя или пароль' });
    }

    const adminModel = new Admin();
    const isPasswordValid = await adminModel.comparePassword(password, admin.password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Неверное имя пользователя или пароль' });
    }

    const token = jwt.sign(
      { id: admin._id, username: admin.username },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        id: admin._id,
        username: admin.username,
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Ошибка входа', details: error.message });
  }
});

// Проверка токена
router.get('/verify', authenticateToken, (req, res) => {
  res.json({ valid: true, user: req.user });
});

// Смена пароля
router.post('/change-password', authenticateToken, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Текущий и новый пароль обязательны' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'Новый пароль должен содержать минимум 6 символов' });
    }

    const admin = await Admin.findById(req.user.id);
    if (!admin) {
      return res.status(404).json({ error: 'Администратор не найден' });
    }

    // Получаем полные данные админа для проверки пароля
    const adminFull = await Admin.findByUsername(admin.username);
    const adminModel = new Admin();
    const isPasswordValid = await adminModel.comparePassword(currentPassword, adminFull.password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Неверный текущий пароль' });
    }

    await Admin.updatePassword(req.user.id, newPassword);

    res.json({ message: 'Пароль успешно изменен' });
  } catch (error) {
    res.status(500).json({ error: 'Ошибка смены пароля', details: error.message });
  }
});

export default router;

