import express from 'express';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import { authenticateToken } from '../middleware/auth.js';
import { Phrase } from '../models/Phrase.js';
import fs from 'fs/promises';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

// Настройка multer для загрузки файлов
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../uploads/phrases');
    await fs.mkdir(uploadDir, { recursive: true });
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const language = req.body.language || 'KZ';
    const ext = path.extname(file.originalname);
    const filename = `phrases_${language}_${Date.now()}${ext}`;
    cb(null, filename);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ||
        file.mimetype === 'application/vnd.ms-excel') {
      cb(null, true);
    } else {
      cb(new Error('Разрешены только Excel файлы (.xlsx, .xls)'));
    }
  },
});

// Получить информацию о загруженных файлах
router.get('/', authenticateToken, async (req, res) => {
  try {
    const phrases = await Phrase.findAll();
    res.json(phrases);
  } catch (error) {
    res.status(500).json({ error: 'Ошибка получения файлов', details: error.message });
  }
});

// Загрузить Excel файл
router.post('/upload', authenticateToken, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Файл не загружен' });
    }

    const { language } = req.body;
    if (!language || !['KZ', 'RU'].includes(language)) {
      await fs.unlink(req.file.path);
      return res.status(400).json({ error: 'Язык должен быть KZ или RU' });
    }

    // Удаляем старый файл для этого языка, если существует
    const oldPhrase = await Phrase.findByLanguage(language);
    if (oldPhrase && oldPhrase.file_url) {
      try {
        await fs.unlink(path.join(__dirname, '..', oldPhrase.file_url));
      } catch (err) {
        console.error('Ошибка удаления старого файла:', err);
      }
      await Phrase.deleteByLanguage(language);
    }

    // Создаем новую запись
    const phrase = await Phrase.create({
      language,
      fileUrl: `/uploads/phrases/${req.file.filename}`,
      fileName: req.file.originalname,
      fileSize: req.file.size,
      uploadedBy: req.user.id,
    });

    res.json({
      message: 'Файл успешно загружен',
      phrase: phrase,
    });
  } catch (error) {
    if (req.file) {
      await fs.unlink(req.file.path).catch(() => {});
    }
    res.status(500).json({ error: 'Ошибка загрузки файла', details: error.message });
  }
});

// Удалить файл
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const phrase = await Phrase.findById(req.params.id);
    if (!phrase) {
      return res.status(404).json({ error: 'Файл не найден' });
    }

    // Удаляем физический файл
    try {
      await fs.unlink(path.join(__dirname, '..', phrase.file_url));
    } catch (err) {
      console.error('Ошибка удаления файла:', err);
    }

    await Phrase.delete(req.params.id);
    res.json({ message: 'Файл успешно удален' });
  } catch (error) {
    res.status(500).json({ error: 'Ошибка удаления файла', details: error.message });
  }
});

export default router;

