import express from 'express';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import { authenticateToken } from '../middleware/auth.js';
import { PublicQuestion } from '../models/PublicQuestion.js';
import fs from 'fs/promises';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

// Настройка multer для загрузки файлов
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../uploads/public-questions');
    await fs.mkdir(uploadDir, { recursive: true });
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const language = req.body.language || 'KZ';
    const ext = path.extname(file.originalname);
    const filename = `questions_${language}_${Date.now()}${ext}`;
    cb(null, filename);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
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
    const questions = await PublicQuestion.findAll();
    res.json(questions);
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
      // Удаляем загруженный файл если язык неверный
      await fs.unlink(req.file.path);
      return res.status(400).json({ error: 'Язык должен быть KZ или RU' });
    }

    // Удаляем старый файл для этого языка, если существует
    const oldQuestion = await PublicQuestion.findByLanguage(language);
    if (oldQuestion && oldQuestion.file_url) {
      try {
        await fs.unlink(path.join(__dirname, '..', oldQuestion.file_url));
      } catch (err) {
        console.error('Ошибка удаления старого файла:', err);
      }
      await PublicQuestion.deleteByLanguage(language);
    }

    // Создаем новую запись
    const publicQuestion = await PublicQuestion.create({
      language,
      fileUrl: `/uploads/public-questions/${req.file.filename}`,
      fileName: req.file.originalname,
      fileSize: req.file.size,
      uploadedBy: req.user.id,
    });

    res.json({
      message: 'Файл успешно загружен',
      question: publicQuestion,
    });
  } catch (error) {
    // Удаляем файл при ошибке
    if (req.file) {
      await fs.unlink(req.file.path).catch(() => {});
    }
    res.status(500).json({ error: 'Ошибка загрузки файла', details: error.message });
  }
});

// Удалить файл
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const question = await PublicQuestion.findById(req.params.id);
    if (!question) {
      return res.status(404).json({ error: 'Файл не найден' });
    }

    // Удаляем физический файл
    try {
      await fs.unlink(path.join(__dirname, '..', question.file_url));
    } catch (err) {
      console.error('Ошибка удаления файла:', err);
    }

    await PublicQuestion.delete(req.params.id);
    res.json({ message: 'Файл успешно удален' });
  } catch (error) {
    res.status(500).json({ error: 'Ошибка удаления файла', details: error.message });
  }
});

export default router;

